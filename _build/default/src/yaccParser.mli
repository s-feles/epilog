type token =
  | VAR of (
# 1 "src/yaccParser.mly"
       string
# 6 "src/yaccParser.mli"
)
  | SYM of (
# 1 "src/yaccParser.mly"
       string
# 11 "src/yaccParser.mli"
)
  | NUM of (
# 2 "src/yaccParser.mly"
       int
# 16 "src/yaccParser.mli"
)
  | BR_OPN
  | BR_CLS
  | ASTERISK
  | COMMA
  | DOT
  | MINUS
  | PLUS
  | SLASH
  | COLON_MINUS
  | IS
  | EOF

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.program
val query :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.query
