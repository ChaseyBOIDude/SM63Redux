extends Node

func read_file(path):
	var file = File.new()
	file.open(path, File.READ)
	var content = file.get_as_text()
	file.close()
	return content

var token_types = {
	"!": "call",
	"%(": "print_call",
	"==": "math_eq",
	"~=": "math_neq",
	">=": "math_gte",
	"<=": "math_lte",
	"&&": "math_and",
	"||": "math_or",
	">": "math_gt",
	"<": "math_lt",
	")": "bracket_right",
	"(": "bracket_left",
	"=": "assign",
	"*": "math_mul",
	"/": "math_div",
	"+": "math_add",
	"-": "math_sub",
	",": "seperator",
	":": "atom",
	"\"": "string",
	"#": "comment",
	"\t": "tab",
}

var math_order = {
	"math_mul": 5,
	"math_div": 5,
	"math_add": 4,
	"math_sub": 4,
	"math_eq": 3,
	"math_neq": 3,
	"math_gte": 3,
	"math_lte": 3,
	"math_gt": 3,
	"math_lt": 3,
	"math_and": 2,
	"math_or": 1,
}

# a handy function to check if a string of bytes is alphanumeric
func is_alphanumeric(s: String):
	for byte in s.to_ascii():
		if !((byte >= 48 && byte <= 57) || (byte >= 65 && byte <= 90) || (byte >= 97 && byte <= 122) || byte == 46):
			return false
	return true

func parse(body: String):
	var tokens = parse_tokens(body)
	interpret(tokens)

func is_math_input(token):
	return token.type == "raw" || token.type == "number"

func is_math_token(token):
	return is_math_input(token) || token.type.begins_with("math_") || token.type.begins_with("bracket_")

func handle_expression(queue: Array):
	var idx = 0
	var size = queue.size()
	# first handle all brackets
	while idx < size:
		var item = queue[idx]
		if typeof(item) == TYPE_ARRAY:
			# if there were brackets, interpret that first
			# we convert back to a string to be consistent
			queue[idx] = handle_expression(queue[idx])
		idx += 1
	
	# handle the math operations
	while size > 1:
		# find the best index to start the calculation from, multiplication goes before addition
		var best = {
			idx = 0,
			order = 0,
		}
		for best_idx in size:
			var type = queue[best_idx].type
			if type.begins_with("math_"):
				var order = math_order[type]
				if order > best.order:
					best.idx = best_idx + 1
					best.order = order
		
		# get the operand and the two numbers to use
		var op = queue[best.idx - 1].type
		var a = float(queue[best.idx - 2].body) if queue[best.idx - 2].type == "number" else 0 #TODO: get variable
		var b = float(queue[best.idx].body) if queue[best.idx].type == "number" else 0 #TODO: get variable
		
		var result = 0
		match op:
			"math_add":
				result = a + b
			"math_sub":
				result = a - b
			"math_div":
				result = a / b
			"math_mul":
				result = a * b
			"math_eq":
				result = 1 if a == b else 0
			"math_neq":
				result = 0 if a == b else 1
			"math_gte":
				result = 1 if a >= b else 0
			"math_lte":
				result = 1 if a <= b else 0
			"math_gt":
				result = 1 if a > b else 0
			"math_lt":
				result = 1 if a < b else 0
			"math_and":
				result = 1 if a != 0 && b != 0 else 0
			"math_or":
				result = 1 if a != 0 || b != 0 else 0
		
		# handle the stack
		queue[best.idx] = {
			body = str(result),
			type = "number"
		}
		queue.pop_at(best.idx - 2)
		queue.pop_at(best.idx - 2)
		size = queue.size()
	return queue[0]

func interpret(tokens):
	var token_size = tokens.size()
	
	var token_idx = 0
	while token_idx < token_size:
		var token = tokens[token_idx]
		
		if is_math_token(token):
			var queue_stack = []
			var current_queue = []
			var current_token_idx = token_idx
			while current_token_idx < token_size && is_math_token(tokens[current_token_idx]):
				var current_token = tokens[current_token_idx]
				if current_token.type == "bracket_left":
					current_token = null
					queue_stack.append(current_queue)
					current_queue = []
				elif current_token.type == "bracket_right":
					current_token = current_queue
					current_queue = queue_stack.pop_back()
				
				if current_token:
					current_queue.append(current_token)
				current_token_idx += 1
			
			token_idx += current_token_idx - token_idx
			var result = handle_expression(current_queue)
			print(result)
			continue
				
		token_idx += 1
		
			#var token_2 = tokens[(token_idx + 2) % token_size]
			

func parse_tokens(body: String):
	var body_length = body.length()
	var tokens = []
	
	var is_comment = false
	var is_atom = false
	var is_string = false
	var cross_token = ""
	var line_nr = 0
	
	# iterate through the entire body
	var char_idx = 0
	while char_idx < body_length:
		var should_do_token_check = !(is_comment || is_atom || is_string)
		
		if body[char_idx] == "\n":
			line_nr += 1
		
		# if we're a comment / atom / string make sure to chain words together
		if is_comment:
			var chr = body[char_idx]
			if chr != "\n":
				cross_token += chr
			else:
				if cross_token != "":
					tokens.back().body += cross_token
					cross_token = ""
				is_comment = false
		elif is_atom:
			var chr = body[char_idx]
			if is_alphanumeric(chr):
				cross_token += chr
			else:
				if cross_token != "":
					tokens.back().body += cross_token
					cross_token = ""
				is_atom = false
		elif is_string:
			var chr_2 = body[char_idx - 2] if char_idx >= 2 else ""
			var chr_1 = body[char_idx - 1] if char_idx >= 1 else ""
			var chr_0 = body[char_idx]
			if chr_0 == "\"" && chr_1 != "\\" && chr_2 != "\\":
				if cross_token != "":
					tokens.back().body += cross_token
					cross_token = ""
				is_string = false
			else:
				cross_token += chr_0
		
		# check each token, see if we match
		var token
		if should_do_token_check:
			for token_type in token_types.keys():
				var substr = body.substr(char_idx, token_type.length())
				if substr == token_type:
					token = {
						body = substr,
						type = token_types[token_type],
						line = line_nr
					}
					break
		
		# add 'raw' tokens, these are literals or variable names
		if should_do_token_check:
			var chr = body[char_idx]
			if is_alphanumeric(chr) && token == null:
				cross_token += chr
			elif cross_token != "":
				tokens.append({
					body = cross_token,
					type = "number" if cross_token.is_valid_float() else "raw",
					line = line_nr
				})
				cross_token = ""
		
		if token:
			if token.type == "comment":
				is_comment = true
			elif token.type == "atom":
				is_atom = true
			elif token.type == "string":
				is_string = true
			
			tokens.append(token)
			char_idx += token.body.length()
		else:
			char_idx += 1
	
	# filter comment tokens
	var returns = []
	for token in tokens:
		if token.type != "comment":
			returns.append(token)
	
	return returns

func _ready():
	var demo: String = read_file("res://src/pipe_script/demo.psl")
	
	parse(demo)
	