-- Error in library: dev.rayteam.rayfox.luppy >
-- FoxBox version: 4.0
-- fox.lua version: 2.2
-- Unix time: 1782830770
-- DocType version: Bea B3
--> ============  METADATA  ============ <--


local Box = {}
Box._config = {
	package = "dev.rayteam.rayfox.luppy", -- Your package name
	version = 1.0, -- dev.rayteam.rayfox.luppy version
	deps = {
		-- ["com.package.name"] = {">=", 1.0}
	},
	optional = {
		-- ["com.package.name"] = {">=", 1.0}
	}
	-- Modes: >=, <=, >, <, ==, ~=
	-- You can mix different modes:
	-- {{">=", 1.0}, {"<", 2.3}, {"~=", 1.58}, ...}
	-- Or 'deps = {}' if none
}

--> ============   CONFIG   ============ <--


local syslib = ...
if type(syslib) ~= "table" then
	return Box
else
	syslib = load(Fox.syslib)(Box._config)
end

--> ============   SYSLIB   ============ <--
--------------------------------------------
--> ============ YOUR CODE: ============ <--


function Box.tokenize(code)
	local tokens = {}
	local chars = {}
	local char_positions = {}
	local pos = 1
	for char_pos, char in utf8.codes(code) do
		chars[pos] = utf8.char(char)
		char_positions[pos] = char_pos
		pos = pos + 1
	end

	local i, n = 1, #chars
	local line, col = 1, 1
	local byte_pos = 1

	local in_string = false
	local string_delimiter = nil
	local in_long_string = false
	local long_string_level = 0
	local in_comment = false
	local comment_type = nil
	local in_number = false
	local current_token = ""
	local token_start_line, token_start_col, token_start_byte

	local function add_token(type, value)
		if value and value ~= "" then
			table.insert(tokens, {
				type = type,
				value = value,
				line = token_start_line or line,
				col = token_start_col or col,
				byte_pos = token_start_byte or byte_pos,
				end_line = line,
				end_col = col
			})
		end
		current_token = ""
		in_number = false
		in_string = false
		in_long_string = false
		string_delimiter = nil
		in_comment = false
		comment_type = nil
	end

	local function schar(pos)
		return pos <= n and chars[pos] or nil
	end

	local function utf8_char_len(c)
		if not c then
			return 1
		end
		local byte = c:byte(1)
		if not byte then
			return 1
		end
		if byte < 0x80 then
			return 1
		end
		if byte < 0xE0 then
			return 2
		end
		if byte < 0xF0 then
			return 3
		end
		return 4
	end

	local function is_whitespace(c)
		return c == ' ' or c == '\t' or c == '\n' or c == '\r'
	end

	local function is_digit(c)
		return c and c >= '0' and c <= '9'
	end

	local function is_letter(c)
		if not c then
			return false
		end
		if (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or c == '_' then
			return true
		end
		local byte = c:byte(1)
		if byte and byte >= 0xC0 then
			return true
		end
		return false
	end

	local function is_hex(c)
		return c and (is_digit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))
	end

	local function is_alphanumeric(c)
		return is_letter(c) or is_digit(c)
	end

	local keywords = {
		["and"] = true,
		["break"] = true,
		["do"] = true,
		["else"] = true,
		["elseif"] = true,
		["end"] = true,
		["false"] = true,
		["for"] = true,
		["function"] = true,
		["goto"] = true,
		["if"] = true,
		["in"] = true,
		["local"] = true,
		["nil"] = true,
		["not"] = true,
		["or"] = true,
		["repeat"] = true,
		["return"] = true,
		["then"] = true,
		["true"] = true,
		["until"] = true,
		["while"] = true
	}

	local function check_long_bracket(start_idx, bracket_char)
		local level = 0
		local j = start_idx + 1
		while j <= n and chars[j] == '=' do
			level = level + 1
			j = j + 1
		end
		if j <= n and chars[j] == bracket_char then
			return level, j - start_idx + 1
		end
		return nil
	end

	local function advance(count)
		for _ = 1, (count or 1) do
			if i > n then
				break
			end
			local c = chars[i]
			local clen = utf8_char_len(c)
			i = i + 1
			byte_pos = byte_pos + clen
			if c == '\n' then
				line = line + 1
				col = 1
			else
				col = col + 1
			end
		end
	end

	local function start_token()
		token_start_line = line
		token_start_col = col
		token_start_byte = byte_pos
		current_token = ""
	end

	while i <= n do
		local char = chars[i]

		if not in_string and not in_comment and char == '-' and schar(i + 1) == '-' then
			if schar(i + 2) == '[' then
				local level, len = check_long_bracket(i + 2, '[')
				if level then
					if current_token ~= "" then
						add_token("WHITESPACE", current_token)
					end
					in_comment = true
					comment_type = "long"
					start_token()
					current_token = ""

					for _ = 1, 2 + len do
						current_token = current_token .. chars[i]
						advance()
					end
					long_string_level = level
					goto continue
				end
			end

			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end
			in_comment = true
			comment_type = "single"
			start_token()
			current_token = '--'
			advance()
			advance()
			goto continue
		end

		if not in_string and not in_comment and char == '[' then
			local level, len = check_long_bracket(i, '[')
			if level then
				if current_token ~= "" then
					add_token("WHITESPACE", current_token)
				end
				in_string = true
				in_long_string = true
				long_string_level = level
				start_token()
				for _ = 1, len do
					current_token = current_token .. chars[i]
					advance()
				end
				goto continue
			end
		end

		if not in_string and not in_comment and (char == '"' or char == "'") then
			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end
			in_string = true
			string_delimiter = char
			start_token()
			current_token = char
			advance()
			goto continue
		end

		if not in_string and not in_comment and not in_number and
			char == '.' and schar(i + 1) == '.' and schar(i + 2) == '.' then
			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end
			for _ = 1, 3 do
				start_token()
				current_token = "."
				add_token("PUNCTUATION", ".")
				advance(1)
			end
			goto continue
		end

		if in_string or in_comment then
			current_token = current_token .. char

			if in_comment and comment_type == "long" and char == ']' then
				local level, len = check_long_bracket(i, ']')
				if level and level == long_string_level then
					for _ = 1, len - 1 do
						if i <= n then
							advance()
							current_token = current_token .. chars[i - 1]
						end
					end
					add_token("COMMENT", current_token)
					advance()
					goto continue
				end
			end

			if in_string and in_long_string and char == ']' then
				local level, len = check_long_bracket(i, ']')
				if level and level == long_string_level then
					for _ = 1, len - 1 do
						if i <= n then
							advance()
							current_token = current_token .. chars[i - 1]
						end
					end
					add_token("STRING", current_token)
					advance()
					goto continue
				end
			end

			if in_string and not in_long_string and char == string_delimiter then
				add_token("STRING", current_token)
				advance()
				goto continue
			end

			if in_comment and comment_type == "single" and (char == '\n' or i == n) then
				add_token("COMMENT", current_token)
				if char == '\n' then
					advance()
				end
				goto continue
			end

			if in_string and not in_long_string and char == '\\' then
				local next_ch = schar(i + 1)
				if next_ch then
					advance()
					current_token = current_token .. next_ch
					advance()
				else
					advance()
				end
				goto continue
			end

			advance()
			goto continue
		end

		local started_number = false
		if not in_number and (is_digit(char) or (char == '.' and schar(i + 1) and is_digit(schar(i + 1)))) then
			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end
			in_number = true
			start_token()
			started_number = true
		end

		if in_number then
			if started_number then
				current_token = char
				advance()
				goto continue
			end

			local is_part_of_number = false
			if char == '.' and not current_token:find("%.") and not current_token:find("[xX]") then
				is_part_of_number = true
			elseif (char == 'e' or char == 'E') and not current_token:find("[eEpP]") and not current_token:find("[xX]") then
				local next_ch = schar(i + 1)
				if next_ch and (is_digit(next_ch) or next_ch == '+' or next_ch == '-') then
					is_part_of_number = true
				end
			elseif (char == 'p' or char == 'P') and not current_token:find("[eEpP]") and current_token:find("0[xX]") then
				local next_ch = schar(i + 1)
				if next_ch and (is_digit(next_ch) or next_ch == '+' or next_ch == '-') then
					is_part_of_number = true
				end
			elseif (char == '+' or char == '-') then
				local prev_ch = current_token:sub(-1)
				if prev_ch == 'e' or prev_ch == 'E' or prev_ch == 'p' or prev_ch == 'P' then
					is_part_of_number = true
				end
			elseif (char == 'x' or char == 'X') and current_token == '0' then
				is_part_of_number = true
			elseif is_hex(char) and current_token:find("0[xX]") then
				is_part_of_number = true
			elseif is_digit(char) then
				is_part_of_number = true
			end

			if is_part_of_number then
				current_token = current_token .. char
				advance()
				goto continue
			else
				add_token("NUMBER", current_token)

				goto continue
			end
		end

		if not in_string and not in_comment and not in_number and is_letter(char) then
			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end
			start_token()
			current_token = char
			advance()
			while i <= n do
				local next_ch = chars[i]
				if next_ch and is_alphanumeric(next_ch) then
					current_token = current_token .. next_ch
					advance()
				else
					break
				end
			end
			if keywords[current_token] then
				add_token("KEYWORD", current_token)
			else
				add_token("IDENTIFIER", current_token)
			end
			goto continue
		end

		if not in_string and not in_comment and not in_number and is_whitespace(char) then
			if current_token ~= "" and not (is_whitespace(current_token:sub(1, 1))) then
				add_token("WHITESPACE", current_token)
			end
			start_token()
			current_token = char
			advance()
			while i <= n do
				local next_ch = chars[i]
				if next_ch and is_whitespace(next_ch) then
					current_token = current_token .. next_ch
					advance()
				else
					break
				end
			end
			add_token("WHITESPACE", current_token)
			goto continue
		end

		if not in_string and not in_comment and not in_number then
			if current_token ~= "" then
				add_token("WHITESPACE", current_token)
			end

			start_token()
			current_token = char

			local two_char_ops = {
				['..'] = true,
				['=='] = true,
				['~='] = true,
				['<='] = true,
				['>='] = true,
				['//'] = true,
				['<<'] = true,
				['>>'] = true
			}

			local next_char = schar(i + 1)
			if next_char and two_char_ops[char .. next_char] then
				current_token = char .. next_char
				add_token("OPERATOR", current_token)
				advance(2)
				goto continue
			end

			local single_ops = {
				['+'] = true,
				['-'] = true,
				['*'] = true,
				['/'] = true,
				['%'] = true,
				['^'] = true,
				['#'] = true,
				['&'] = true,
				['|'] = true,
				['~'] = true,
				['='] = true,
				['<'] = true,
				['>'] = true
			}

			local punctuation = {
				[','] = true,
				[';'] = true,
				[':'] = true,
				['('] = true,
				[')'] = true,
				['{'] = true,
				['}'] = true,
				['.'] = true,
				['['] = true,
				[']'] = true
			}

			if single_ops[char] then
				add_token("OPERATOR", current_token)
				advance()
				goto continue
			end

			if punctuation[char] then
				add_token("PUNCTUATION", current_token)
				advance()
				goto continue
			end

			add_token("UNKNOWN", current_token)
			advance()
			goto continue
		end

		::continue::
	end

	if current_token ~= "" then
		if in_string then
			add_token("STRING", current_token)
		elseif in_comment then
			add_token("COMMENT", current_token)
		elseif in_number then
			add_token("NUMBER", current_token)
		else
			add_token("WHITESPACE", current_token)
		end
	end

	return tokens
end

function Box.ast(tokens)
	local PREC = {
		["or"] = 1,
		["and"] = 2,
		["<"] = 3,
		[">"] = 3,
		["<="] = 3,
		[">="] = 3,
		["~="] = 3,
		["=="] = 3,
		["|"] = 4,
		["~"] = 5,
		["&"] = 6,
		["<<"] = 7,
		[">>"] = 7,
		[".."] = 8,
		["+"] = 9,
		["-"] = 9,
		["*"] = 10,
		["/"] = 10,
		["//"] = 10,
		["%"] = 10,
		["^"] = 12
	}
	local PREC_UNARY = 11

	local pos = 1
	local n = #tokens

	local function skip_trivia()
		while pos <= n and (tokens[pos].type == "WHITESPACE" or tokens[pos].type == "COMMENT") do
			pos = pos + 1
		end
	end

	local function current()
		skip_trivia()
		if pos <= n then
			return tokens[pos]
		else
			return {
				type = "EOF",
				value = ""
			}
		end
	end

	local function advance()
		local tok = current()
		if tok.type ~= "EOF" then
			pos = pos + 1
		end
		return tok
	end

	local function expect(typ, val)
		local tok = advance()
		if tok.type ~= typ then
			local ctx = current()
			syslib.error(string.format("Expected %s, got %s ('%s') at line %d, col %d. Next: %s ('%s')", typ, tok.type,
				tostring(tok.value), tok.line or 0, tok.col or 0, ctx.type, tostring(ctx.value)))
		end
		if val and tok.value ~= val then
			syslib.error(string.format("Expected '%s', got '%s' at line %d, col %d", val, tostring(tok.value),
				tok.line or 0, tok.col or 0))
		end
		return tok
	end

	local function is_block_end(tok)
		if tok.type == "EOF" then
			return true
		end
		if tok.type == "KEYWORD" then
			local v = tok.value
			if v == "end" or v == "until" or v == "elseif" or v == "else" then
				return true
			end
		end
		return false
	end

	local function is_unary_op(tok)
		if tok.type == "OPERATOR" then
			local v = tok.value
			if v == "#" or v == "-" or v == "~" then
				return true
			end
		elseif tok.type == "KEYWORD" and tok.value == "not" then
			return true
		end
		return false
	end

	local function try_parse_varargs()
		local t = current()
		if t.type == "PUNCTUATION" and t.value == "." then
			if pos + 1 <= n and tokens[pos + 1].type == "PUNCTUATION" and tokens[pos + 1].value == "." and pos + 2 <= n and
				tokens[pos + 2].type == "PUNCTUATION" and tokens[pos + 2].value == "." then
				pos = pos + 3
				skip_trivia()
				return true
			end
		end
		return false
	end

	local parse_expression, parse_prefixexp, parse_atom, parse_table_constructor
	local parse_parameters, parse_arguments, parse_block, parse_statement
	local parse_assignment_or_call, parse_if, parse_while, parse_repeat
	local parse_for, parse_do, parse_return, parse_local_statement
	local parse_function_declaration

	parse_atom = function()
		local t = current()
		if t.type == "KEYWORD" then
			if t.value == "nil" then
				advance();
				return {
					type = "Literal",
					value = nil
				}
			elseif t.value == "true" then
				advance();
				return {
					type = "Literal",
					value = true
				}
			elseif t.value == "false" then
				advance();
				return {
					type = "Literal",
					value = false
				}
			elseif t.value == "function" then
				advance()
				local params = parse_parameters()
				local body = parse_block()
				expect("KEYWORD", "end")
				return {
					type = "FunctionExpression",
					parameters = params,
					body = body
				}
			else
				syslib.error("Unexpected keyword in expression: " .. t.value)
			end
		elseif t.type == "NUMBER" then
			advance()
			return {
				type = "Literal",
				value = tonumber(t.value)
			}
		elseif t.type == "STRING" then
			advance()
			return {
				type = "Literal",
				value = t.value
			}
		elseif t.type == "PUNCTUATION" then
			if t.value == "(" then
				advance()
				local expr = parse_expression()
				expect("PUNCTUATION", ")")
				return expr
			elseif t.value == "{" then
				return parse_table_constructor()
			else
				syslib.error("Unexpected punctuation in expression: " .. t.value)
			end
		elseif t.type == "IDENTIFIER" then
			advance()
			return {
				type = "Identifier",
				name = t.value
			}
		else
			syslib.error("Unexpected token in expression: " .. t.type .. " (" .. t.value .. ")")
		end
	end

	parse_parameters = function()
		local t = current()
		if t.type ~= "PUNCTUATION" or t.value ~= "(" then
			syslib.error("Expected '(' for parameters, got " .. t.type .. " ('" .. t.value .. "')")
		end
		advance()
		local params = {}
		t = current()
		if not (t.type == "PUNCTUATION" and t.value == ")") then
			while true do
				if try_parse_varargs() then
					table.insert(params, {
						type = "Varargs"
					})
					if current().type ~= "PUNCTUATION" or current().value ~= ")" then
						syslib.error("Varargs must be the last parameter")
					end
					break
				else
					local name_tok = current()
					if name_tok.type == "IDENTIFIER" then
						advance()
						table.insert(params, name_tok.value)
					else
						syslib.error("Expected parameter name, got " .. name_tok.type)
					end
					t = current()
					if t.type == "PUNCTUATION" and t.value == "," then
						advance()
					else
						break
					end
				end
			end
		end
		expect("PUNCTUATION", ")")
		return params
	end

	parse_arguments = function()
		local t = current()
		local args = {}
		if t.type == "PUNCTUATION" and t.value == "(" then
			advance()
			if not (current().type == "PUNCTUATION" and current().value == ")") then
				repeat
					table.insert(args, parse_expression())
					if current().type == "PUNCTUATION" and current().value == "," then
						advance()
					else
						break
					end
				until false
			end
			expect("PUNCTUATION", ")")
		elseif t.type == "STRING" or (t.type == "PUNCTUATION" and t.value == "{") then
			table.insert(args, parse_atom())
		else
			syslib.error("Expected function arguments, got " .. t.type)
		end
		return args
	end

	parse_table_constructor = function()
		advance()
		local fields = {}
		while true do
			if current().type == "PUNCTUATION" and current().value == "}" then
				advance()
				break
			end
			local key, value, kind

			if current().type == "PUNCTUATION" and current().value == "[" then
				advance()
				key = parse_expression()
				expect("PUNCTUATION", "]")
				expect("OPERATOR", "=")
				value = parse_expression()
				kind = "key_value"
			else
				local saved_pos = pos

				if current().type == "IDENTIFIER" then
					local ident = current().value
					advance()
					if current().type == "OPERATOR" and current().value == "=" then
						advance()
						key = ident
						value = parse_expression()
						kind = "key_value"
					else
						pos = saved_pos
						value = parse_expression()
						kind = "value"
					end
				else
					value = parse_expression()
					kind = "value"
				end
			end

			table.insert(fields, {
				key = key,
				value = value,
				kind = kind
			})

			if current().type == "PUNCTUATION" and (current().value == "," or current().value == ";") then
				advance()
			elseif current().type == "PUNCTUATION" and current().value == "}" then

			end
		end
		return {
			type = "TableConstructor",
			fields = fields
		}
	end

	parse_prefixexp = function()
		local left
		if try_parse_varargs() then
			left = {
				type = "Varargs"
			}
		else
			left = parse_atom()
		end
		while true do
			local t = current()
			if t.type == "PUNCTUATION" then
				if t.value == "." then
					advance()
					local member = expect("IDENTIFIER").value
					left = {
						type = "Member",
						object = left,
						member = member
					}
				elseif t.value == "[" then
					advance()
					local index = parse_expression()
					expect("PUNCTUATION", "]")
					left = {
						type = "Index",
						object = left,
						index = index
					}
				elseif t.value == ":" then
					local next_t = tokens[pos + 1]

					local saved_pos = pos
					advance()
					skip_trivia()
					local after = current()
					pos = saved_pos
					if after.type == "PUNCTUATION" and after.value == ":" then
						break
					end

					advance()
					local method = expect("IDENTIFIER").value
					local args = parse_arguments()
					left = {
						type = "MethodCall",
						object = left,
						method = method,
						arguments = args
					}
				elseif t.value == "(" then
					local args = parse_arguments()
					left = {
						type = "Call",
						func = left,
						arguments = args
					}
				else
					break
				end
			elseif t.type == "STRING" or (t.type == "PUNCTUATION" and t.value == "{") then
				local arg = parse_atom()
				left = {
					type = "Call",
					func = left,
					arguments = { arg }
				}
			else
				break
			end
		end
		return left
	end

	parse_expression = function(min_prec)
		min_prec = min_prec or 0
		local left
		local tok = current()
		if is_unary_op(tok) then
			local op = tok.value
			advance()
			local operand = parse_expression(PREC_UNARY)
			left = {
				type = "UnaryOp",
				op = op,
				operand = operand
			}
		else
			left = parse_prefixexp()
		end
		while true do
			local tok = current()
			local prec = nil
			if tok.type == "OPERATOR" then
				prec = PREC[tok.value]
			elseif tok.type == "KEYWORD" and (tok.value == "and" or tok.value == "or") then
				prec = PREC[tok.value]
			end
			if prec and prec >= min_prec then
				local op = tok.value
				advance()
				local next_prec = (op == "^" --[[or op == ".."]]) and prec or (prec + 1)
				local right = parse_expression(next_prec)
				left = {
					type = "BinaryOp",
					op = op,
					left = left,
					right = right
				}
			else
				break
			end
		end
		return left
	end

	parse_block = function()
		local statements = {}
		while not is_block_end(current()) do
			local stmt = parse_statement()
			if stmt and stmt.type ~= "EmptyStatement" then
				table.insert(statements, stmt)
			end
		end
		return {
			type = "Block",
			statements = statements
		}
	end

	parse_assignment_or_call = function(first)
		if current().type == "OPERATOR" and current().value == "=" then
			local targets = { first }
			while current().type == "PUNCTUATION" and current().value == "," do
				advance()
				table.insert(targets, parse_prefixexp())
			end
			expect("OPERATOR", "=")
			local values = {}
			repeat
				table.insert(values, parse_expression())
				if current().type == "PUNCTUATION" and current().value == "," then
					advance()
				else
					break
				end
			until false
			return {
				type = "Assignment",
				targets = targets,
				values = values
			}
		else
			return {
				type = "ExpressionStatement",
				expression = first
			}
		end
	end

	parse_if = function()
		advance()
		local conditions = {}
		local blocks = {}
		table.insert(conditions, parse_expression())
		expect("KEYWORD", "then")
		table.insert(blocks, parse_block())
		while current().type == "KEYWORD" and current().value == "elseif" do
			advance()
			table.insert(conditions, parse_expression())
			expect("KEYWORD", "then")
			table.insert(blocks, parse_block())
		end
		if current().type == "KEYWORD" and current().value == "else" then
			advance()
			table.insert(conditions, {
				type = "ElseMarker"
			})
			table.insert(blocks, parse_block())
		end
		expect("KEYWORD", "end")
		return {
			type = "If",
			conditions = conditions,
			blocks = blocks
		}
	end

	parse_while = function()
		advance()
		local cond = parse_expression()
		expect("KEYWORD", "do")
		local body = parse_block()
		expect("KEYWORD", "end")
		return {
			type = "While",
			condition = cond,
			body = body
		}
	end

	parse_repeat = function()
		advance()
		local body = parse_block()
		expect("KEYWORD", "until")
		local cond = parse_expression()
		return {
			type = "Repeat",
			body = body,
			condition = cond
		}
	end

	parse_for = function()
		advance()
		local var = expect("IDENTIFIER").value
		if current().type == "OPERATOR" and current().value == "=" then
			advance()
			local start = parse_expression()
			expect("PUNCTUATION", ",")
			local end_expr = parse_expression()
			local step = nil
			if current().type == "PUNCTUATION" and current().value == "," then
				advance()
				step = parse_expression()
			end
			expect("KEYWORD", "do")
			local body = parse_block()
			expect("KEYWORD", "end")
			return {
				type = "ForNumeric",
				variable = var,
				start = start,
				["end"] = end_expr,
				step = step,
				body = body
			}
		else
			local vars = { var }
			while current().type == "PUNCTUATION" and current().value == "," do
				advance()
				table.insert(vars, expect("IDENTIFIER").value)
			end
			expect("KEYWORD", "in")
			local iterators = {}
			repeat
				table.insert(iterators, parse_expression())
				if current().type == "PUNCTUATION" and current().value == "," then
					advance()
				else
					break
				end
			until false
			expect("KEYWORD", "do")
			local body = parse_block()
			expect("KEYWORD", "end")
			return {
				type = "ForGeneric",
				variables = vars,
				iterators = iterators,
				body = body
			}
		end
	end

	parse_do = function()
		advance()
		local body = parse_block()
		expect("KEYWORD", "end")
		return {
			type = "Do",
			body = body
		}
	end

	parse_return = function()
		advance()
		local values = {}
		if not is_block_end(current()) and not (current().type == "PUNCTUATION" and current().value == ";") then
			repeat
				table.insert(values, parse_expression())
				if current().type == "PUNCTUATION" and current().value == "," then
					advance()
				else
					break
				end
			until false
		end
		if current().type == "PUNCTUATION" and current().value == ";" then
			advance()
		end
		return {
			type = "Return",
			values = values
		}
	end

	parse_local_statement = function()
		advance()
		if current().type == "KEYWORD" and current().value == "function" then
			advance()
			local segments = {}
			local is_method = false
			table.insert(segments, expect("IDENTIFIER").value)
			while true do
				local t = current()
				if t.type == "PUNCTUATION" and t.value == "." then
					advance()
					table.insert(segments, expect("IDENTIFIER").value)
				elseif t.type == "PUNCTUATION" and t.value == ":" then
					advance()
					is_method = true
					table.insert(segments, expect("IDENTIFIER").value)
					break
				else
					break
				end
			end
			local params = parse_parameters()
			if is_method then
				table.insert(params, 1, "self")
			end
			local body = parse_block()
			expect("KEYWORD", "end")
			return {
				type = "FunctionDeclaration",
				name_segments = segments,
				parameters = params,
				body = body,
				is_local = true
			}
		else
			local names = {}
			repeat
				table.insert(names, expect("IDENTIFIER").value)
				if current().type == "PUNCTUATION" and current().value == "," then
					advance()
				else
					break
				end
			until false
			local values = {}
			if current().type == "OPERATOR" and current().value == "=" then
				advance()
				repeat
					table.insert(values, parse_expression())
					if current().type == "PUNCTUATION" and current().value == "," then
						advance()
					else
						break
					end
				until false
			end
			return {
				type = "LocalDeclaration",
				names = names,
				values = values
			}
		end
	end

	parse_function_declaration = function()
		advance()
		local segments = {}
		local is_method = false
		table.insert(segments, expect("IDENTIFIER").value)
		while true do
			local t = current()
			if t.type == "PUNCTUATION" and t.value == "." then
				advance()
				table.insert(segments, expect("IDENTIFIER").value)
			elseif t.type == "PUNCTUATION" and t.value == ":" then
				advance()
				is_method = true
				table.insert(segments, expect("IDENTIFIER").value)
				break
			else
				break
			end
		end
		local params = parse_parameters()
		if is_method then
			table.insert(params, 1, "self")
		end
		local body = parse_block()
		expect("KEYWORD", "end")
		return {
			type = "FunctionDeclaration",
			name_segments = segments,
			parameters = params,
			body = body,
			is_local = false
		}
	end

	parse_statement = function()
		local t = current()
		if t.type == "PUNCTUATION" and t.value == ";" then
			advance()
			return {
				type = "EmptyStatement"
			}
		end
		if t.type == "KEYWORD" then
			local kw = t.value
			if kw == "if" then
				return parse_if()
			elseif kw == "while" then
				return parse_while()
			elseif kw == "repeat" then
				return parse_repeat()
			elseif kw == "for" then
				return parse_for()
			elseif kw == "do" then
				return parse_do()
			elseif kw == "return" then
				return parse_return()
			elseif kw == "break" then
				advance();
				return {
					type = "Break"
				}
			elseif kw == "goto" then
				advance()
				local lbl = expect("IDENTIFIER").value
				return {
					type = "Goto",
					label = lbl
				}
			elseif kw == "local" then
				return parse_local_statement()
			elseif kw == "function" then
				return parse_function_declaration()
			else
				syslib.error("Unexpected keyword: " .. kw)
			end
		elseif t.type == "PUNCTUATION" and t.value == ":" then
			advance()
			expect("PUNCTUATION", ":")
			local name = expect("IDENTIFIER").value
			expect("PUNCTUATION", ":")
			expect("PUNCTUATION", ":")
			return {
				type = "Label",
				name = name
			}
		else
			local first = parse_prefixexp()
			return parse_assignment_or_call(first)
		end
	end

	local function parse_chunk()
		local statements = {}
		while current().type ~= "EOF" do
			local stmt = parse_statement()
			if stmt and stmt.type ~= "EmptyStatement" then
				table.insert(statements, stmt)
			end
		end
		return {
			type = "Chunk",
			body = {
				type = "Block",
				statements = statements
			}
		}
	end

	return parse_chunk()
end

return Box
