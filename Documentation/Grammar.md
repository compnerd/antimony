
Whitespace is comprised of spaces (\U{0020}), horizontal tabs (\U{0009}),
carriage returns (\U{000d}), and newlines (\U{000a}).

Comments start at the character '#' and stop at the next newline.

```ebnf
file = statement-list .

(* statemnt *)
statement = assignment | call | condition .
assignment = ( identifier | array-access | scope-access ) assignment-operator expression .
call = identifier '(' [ expression-list ] ')' [ block ] .
condition = 'if' '(' expression ')' block
            [ 'else' ( condition | block ) ] .
block = '{' statement-list '}' .
statement-list = { statement } .

(* expression *)
expression = unary-expression
           | expression binary-operator expression .
unary-expression = primary-expression
                 | unary-operator unary-expression .
primary-expression = identifier
                   | integer
                   | string
                   | call
                   | array-access
                   | scope-access
                   | block
                   | '(' expression ')'
                   | '[' [ expression-list [ ',' ] ]']' .
array-access = identifier '[' expression ']' .
scope-acess = identifier '.' identifier .
expression-list = expression { ',' expression } .

(* operators *)
assignment-operator = '=' | '+=' | '-=' .
unary-operator = '!' .
binary-operator = '+' | '-'
                | '<' | '<=' | '>' | '>='
                | '==' | '!='
                | '&&'
                | '||' .

(* terminals *)
identifier = letter { letter | digit } .
letter = ? 'A' ... 'Z' | 'a' ... 'z' | '_' ? .
digit = ? '0' ... '9' ? .

integer = [ '-' ] digit { digit } .

string = '"' { char | escape | expansion } '"' .
escape = '\' ( '$' | '"' | char ) .
expansion = '$' ( identifier | bracket-expansion | hex-value } .
bracket-expansion = '{' ( identifier | array-access | scope-access ) '}' .
hex-value = '0x' ( digit | hex-letter ) { ( digit | hex-letter ) } .
hex-letter = 'a' | 'b' | 'c' | 'd' | 'e' | 'f' | 'A' | 'B' | 'C' | 'D' | 'E' | 'F' .
char = ? any character except '$', '"', or newline ? .
```
