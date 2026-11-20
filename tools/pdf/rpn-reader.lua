--[[
Pandoc custom reader for the RPN documents (used by tools/pdf/build-pdf.sh).

Each input file is parsed as GitHub-flavoured Markdown, so content and heading
anchors match the GitHub rendering, and is then adapted for rpn-style.typ:

* the level-1 heading becomes the document title block (rpn-doc-start), using
  the "Control field" table for the document ID, revision, status and date;
* the document's table of contents is inserted before its first section;
* tables become breakable Typst tables with content-based column widths;
* links are rewritten: to an internal anchor when the target is in the same
  PDF, to the sibling PDF when the target is published as a PDF, otherwise to
  the file in the repository.

Several inputs produce one combined PDF: a set cover and contents are added and
every anchor is prefixed with the document key (e.g. "srs:") to stay unique.

Environment (set by build-pdf.sh):
  RPN_PDF_DOCS  space-separated repository paths of the documents published as
                individual PDFs (same output directory, named <basename>.pdf)
  RPN_REPO_URL  base URL for other repository files, e.g.
                https://github.com/<owner>/<repo>/blob/main
]]

local stringify = pandoc.utils.stringify

local function normalize(path)
  local parts = {}
  for part in path:gmatch('[^/]+') do
    if part == '..' and #parts > 0 and parts[#parts] ~= '..' then
      table.remove(parts)
    elseif part ~= '.' then
      table.insert(parts, part)
    end
  end
  return table.concat(parts, '/')
end

local function resolve(from_file, target)
  local dir = from_file:match('^(.*)/[^/]*$')
  return normalize(dir and (dir .. '/' .. target) or target)
end

local function basename_noext(path)
  return (path:match('([^/]*)$'):gsub('%.[^.]*$', ''))
end

local published = {}
for path in (os.getenv('RPN_PDF_DOCS') or ''):gmatch('%S+') do
  published[normalize(path)] = true
end
local repo_url = (os.getenv('RPN_REPO_URL') or ''):gsub('/+$', '')

local function typst_string(s)
  return '"' .. s:gsub('\\', '\\\\'):gsub('"', '\\"') .. '"'
end

local function typst_content(inlines)
  local markup = pandoc.write(pandoc.Pandoc({ pandoc.Plain(inlines) }), 'typst')
  return '[' .. markup:gsub('%s+$', '') .. ']'
end

local function raw(code)
  return pandoc.RawBlock('typst', code)
end

-- Columns whose longest cell has at most this many characters are sized to
-- their content, as long as together they leave room for the wider columns.
-- Wider columns share the remaining width in proportion to the amount of text
-- they hold (at least a fifth of the widest one's share).
local AUTO_COLUMN_CHARS = 36
local AUTO_BUDGET_CHARS = 90
local MIN_SHARE = 20

local ALIGN = { AlignLeft = 'left', AlignRight = 'right', AlignCenter = 'center' }

local function cell_markup(cell)
  local markup = pandoc.write(pandoc.Pandoc(cell.contents), 'typst'):gsub('%s+$', '')
  return '[' .. markup .. ']'
end

local function row_markup(row)
  local cells = {}
  for _, cell in ipairs(row.cells) do
    table.insert(cells, cell_markup(cell))
  end
  return table.concat(cells, ', ') .. ','
end

-- Pandoc wraps tables in a centred figure with equal or default column
-- widths; emit a plain breakable table with content-based widths instead.
local function table_markup(tbl)
  local ncols = #tbl.colspecs
  local longest, total = {}, {}
  for c = 1, ncols do
    longest[c], total[c] = 0, 0
  end
  local function measure(rows, is_body)
    for _, row in ipairs(rows) do
      for c, cell in ipairs(row.cells) do
        local length = utf8.len(stringify(cell.contents)) or 0
        longest[c] = math.max(longest[c], length)
        if is_body then
          total[c] = total[c] + length
        end
      end
    end
  end
  measure(tbl.head.rows, false)
  for _, body in ipairs(tbl.bodies) do
    measure(body.body, true)
  end

  local is_auto, auto_chars, has_fr = {}, 0, false
  for c = 1, ncols do
    is_auto[c] = longest[c] <= AUTO_COLUMN_CHARS
    if is_auto[c] then
      auto_chars = auto_chars + longest[c]
    else
      has_fr = true
    end
  end
  while has_fr and auto_chars > AUTO_BUDGET_CHARS do
    local demote
    for c = 1, ncols do
      if is_auto[c] and (not demote or longest[c] > longest[demote]) then
        demote = c
      end
    end
    is_auto[demote] = false
    auto_chars = auto_chars - longest[demote]
  end

  local widest = 1
  for c = 1, ncols do
    if not is_auto[c] then
      widest = math.max(widest, total[c])
    end
  end
  local columns, aligns = {}, {}
  for c = 1, ncols do
    if is_auto[c] then
      columns[c] = 'auto'
    else
      columns[c] = math.max(MIN_SHARE, math.floor(100 * total[c] / widest + 0.5)) .. 'fr'
    end
    aligns[c] = ALIGN[tbl.colspecs[c][1]] or 'auto'
  end

  local lines = {
    '#table(',
    '  columns: (' .. table.concat(columns, ', ') .. ',),',
    '  align: (' .. table.concat(aligns, ', ') .. ',),',
  }
  if #tbl.head.rows > 0 then
    table.insert(lines, '  table.header(')
    for _, row in ipairs(tbl.head.rows) do
      table.insert(lines, '    ' .. row_markup(row))
    end
    table.insert(lines, '  ),')
    table.insert(lines, '  table.hline(),')
  end
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      table.insert(lines, '  ' .. row_markup(row))
    end
  end
  table.insert(lines, ')')
  return table.concat(lines, '\n')
end

-- Key/value rows of the first table before section 1 that has a "Document ID".
local function control_fields(blocks)
  for _, block in ipairs(blocks) do
    if block.t == 'Header' and block.level == 2 then
      break
    end
    if block.t == 'Table' then
      local fields = {}
      for _, body in ipairs(block.bodies) do
        for _, row in ipairs(body.body) do
          if #row.cells >= 2 then
            fields[stringify(row.cells[1].contents)] =
              pandoc.utils.blocks_to_inlines(row.cells[2].contents)
          end
        end
      end
      if fields['Document ID'] then
        return fields
      end
    end
  end
  return {}
end

function Reader(inputs, opts)
  local docs, by_path = {}, {}
  for _, source in ipairs(inputs) do
    local path = normalize(source.name)
    local doc = {
      path = path,
      key = basename_noext(path),
      blocks = pandoc.read(source.text, 'gfm', opts).blocks,
    }
    for i, block in ipairs(doc.blocks) do
      if block.t == 'Header' and block.level == 1 then
        doc.title_index, doc.title = i, block.content
        doc.title_id = block.identifier
        break
      end
    end
    doc.title = doc.title or pandoc.Inlines(doc.key)
    doc.title_id = (doc.title_id or '') ~= '' and doc.title_id or doc.key:lower()
    table.insert(docs, doc)
    by_path[path] = doc
  end
  local combined = #docs > 1

  local function anchor(doc, id)
    return combined and (doc.key:lower() .. ':' .. id) or id
  end

  local function rewrite_link(doc, link)
    if link.target:match('^%a[%w+.-]*:') then
      return nil -- absolute URL (https:, mailto:, ...)
    end
    local path, fragment = link.target:match('^([^#]*)#?(.*)$')
    local dest = path == '' and doc.path or resolve(doc.path, path)
    local other = by_path[dest]
    if other then
      link.target = '#' .. anchor(other, fragment ~= '' and fragment or other.title_id)
    elseif published[dest] then
      link.target = basename_noext(dest) .. '.pdf'
        .. (fragment ~= '' and ('#nameddest=' .. fragment) or '')
    elseif repo_url ~= '' then
      link.target = repo_url .. '/' .. dest .. (fragment ~= '' and ('#' .. fragment) or '')
    else
      return link.content
    end
    return link
  end

  local out = pandoc.Blocks({})
  if combined then
    out:insert(raw('#rpn-set-front()'))
  end

  local dates = {}
  for _, doc in ipairs(docs) do
    local fields = control_fields(doc.blocks)
    local function field(name)
      return fields[name] and stringify(fields[name]) or ''
    end
    local start_label = anchor(doc, doc.title_id)
    local end_label = anchor(doc, 'rpn-end')
    table.insert(dates, field('Date'))

    out:insert(raw(table.concat({
      '#rpn-doc-start(',
      '  anchor: ' .. typst_string(start_label) .. ',',
      '  id: ' .. typst_string(field('Document ID') ~= '' and field('Document ID') or ('RPN-' .. doc.key)) .. ',',
      '  title: ' .. typst_string(stringify(doc.title)) .. ',',
      '  revision: ' .. typst_string(field('Revision')) .. ',',
      '  date: ' .. typst_string(field('Date')) .. ',',
      '  status: ' .. typst_content(fields['Status'] or pandoc.Inlines({})) .. ',',
      ')',
    }, '\n')))

    local filter = {
      Link = function(link) return rewrite_link(doc, link) end,
      Header = function(header)
        if header.identifier ~= '' then
          header.identifier = anchor(doc, header.identifier)
          return header
        end
      end,
      -- Block elements are filtered after inlines, so links are already rewritten.
      Table = function(tbl) return raw(table_markup(tbl)) end,
    }
    local contents_inserted = false
    for i, block in ipairs(doc.blocks) do
      if i ~= doc.title_index then
        if not contents_inserted and block.t == 'Header' and block.level == 2 then
          out:insert(raw('#rpn-doc-contents(start: ' .. typst_string(start_label)
            .. ', end: ' .. typst_string(end_label) .. ')'))
          contents_inserted = true
        end
        out:extend(pandoc.Blocks({ block }):walk(filter))
      end
    end
    out:insert(raw('#rpn-doc-end(' .. typst_string(end_label) .. ')'))
  end

  table.sort(dates)
  return pandoc.Pandoc(out, {
    title = pandoc.Inlines(combined and 'RPN specification set' or stringify(docs[1].title)),
    date = dates[#dates] or '',
  })
end
