# 1 "src/lexer.mll"
 

let raise_error (lexbuf : Lexing.lexbuf) reason =
  let pos =
    { Ast.start  = lexbuf.lex_start_p
    ; Ast.length = lexbuf.lex_curr_p.pos_cnum - lexbuf.lex_start_p.pos_cnum
    }
  in raise (Errors.Parse_error(pos, reason))

let sym_map =
  let open YaccParser in
  [ "*",  ASTERISK
  ; ",",  COMMA
  ; ".",  DOT
  ; "-",  MINUS
  ; "+",  PLUS
  ; "/",  SLASH
  ; ":-", COLON_MINUS
  ; "is", IS
  ] |> List.to_seq |> Hashtbl.of_seq

let tokenize_sym str =
  match Hashtbl.find_opt sym_map str with
  | None     -> YaccParser.SYM str
  | Some tok -> tok

let tokenize_num lexbuf str =
  try YaccParser.NUM (int_of_string str) with
  | Failure _ ->
    raise_error lexbuf (InvalidNumber str)


# 35 "src/lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base =
   "\000\000\244\255\245\255\079\000\160\000\235\000\069\001\250\255\
    \251\255\252\255\106\001\254\255\007\000\143\001\160\000\161\000\
    \253\255\044\000\255\255\254\255\162\000\194\000\254\255\255\255\
    ";
  Lexing.lex_backtrk =
   "\255\255\255\255\255\255\009\000\008\000\007\000\006\000\255\255\
    \255\255\255\255\006\000\255\255\000\000\002\000\255\255\003\000\
    \255\255\004\000\255\255\255\255\255\255\002\000\255\255\255\255\
    ";
  Lexing.lex_default =
   "\001\000\000\000\000\000\255\255\255\255\255\255\255\255\000\000\
    \000\000\000\000\255\255\000\000\255\255\255\255\015\000\015\000\
    \000\000\255\255\000\000\000\000\021\000\021\000\000\000\000\000\
    ";
  Lexing.lex_trans =
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\012\000\011\000\012\000\012\000\012\000\000\000\000\000\
    \012\000\000\000\012\000\012\000\012\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \012\000\006\000\000\000\006\000\006\000\009\000\006\000\012\000\
    \008\000\007\000\006\000\006\000\006\000\006\000\006\000\010\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\019\000\000\000\000\000\006\000\005\000\
    \000\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\000\000\006\000\000\000\006\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\018\000\255\255\023\000\000\000\003\000\000\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\017\000\255\255\255\255\000\000\000\000\000\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\000\000\000\000\000\000\000\000\004\000\
    \002\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\000\000\000\000\
    \000\000\000\000\005\000\000\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\006\000\000\000\
    \006\000\006\000\000\000\006\000\000\000\000\000\000\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\000\000\000\000\
    \000\000\000\000\000\000\006\000\000\000\006\000\006\000\000\000\
    \006\000\000\000\000\000\000\000\013\000\006\000\006\000\006\000\
    \006\000\006\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \016\000\255\255\022\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\000\000\000\000\000\000\000\000\000\000\
    \006\000\000\000\006\000\006\000\000\000\006\000\000\000\000\000\
    \000\000\006\000\006\000\006\000\006\000\006\000\006\000\000\000\
    \000\000\006\000\255\255\006\000\000\000\000\000\000\000\000\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\006\000\000\000\
    \006\000\000\000\000\000\000\000\000\000\006\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\006\000\000\000\006\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_check =
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\000\000\000\000\000\000\255\255\255\255\
    \012\000\255\255\012\000\012\000\012\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\000\000\255\255\000\000\000\000\000\000\000\000\012\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\017\000\255\255\255\255\000\000\000\000\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\000\000\255\255\000\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\014\000\015\000\020\000\255\255\003\000\255\255\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\003\000\003\000\003\000\003\000\003\000\003\000\
    \003\000\003\000\014\000\015\000\021\000\255\255\255\255\255\255\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\255\255\255\255\255\255\255\255\004\000\
    \000\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\004\000\004\000\004\000\004\000\004\000\
    \004\000\004\000\004\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\255\255\255\255\
    \255\255\255\255\005\000\255\255\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\005\000\005\000\
    \005\000\005\000\005\000\005\000\005\000\005\000\006\000\255\255\
    \006\000\006\000\255\255\006\000\255\255\255\255\255\255\006\000\
    \006\000\006\000\006\000\006\000\006\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\255\255\255\255\
    \255\255\255\255\255\255\010\000\255\255\010\000\010\000\255\255\
    \010\000\255\255\255\255\255\255\010\000\010\000\010\000\010\000\
    \010\000\010\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \014\000\015\000\020\000\006\000\010\000\010\000\010\000\010\000\
    \010\000\010\000\010\000\255\255\255\255\255\255\255\255\255\255\
    \013\000\255\255\013\000\013\000\255\255\013\000\255\255\255\255\
    \255\255\013\000\013\000\013\000\013\000\013\000\013\000\255\255\
    \255\255\006\000\021\000\006\000\255\255\255\255\255\255\255\255\
    \010\000\013\000\013\000\013\000\013\000\013\000\013\000\013\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\010\000\255\255\
    \010\000\255\255\255\255\255\255\255\255\013\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\013\000\255\255\013\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    ";
  Lexing.lex_base_code =
   "";
  Lexing.lex_backtrk_code =
   "";
  Lexing.lex_default_code =
   "";
  Lexing.lex_trans_code =
   "";
  Lexing.lex_check_code =
   "";
  Lexing.lex_code =
   "";
}

let rec token lexbuf =
   __ocaml_lex_token_rec lexbuf 0
and __ocaml_lex_token_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 44 "src/lexer.mll"
                ( token lexbuf )
# 241 "src/lexer.ml"

  | 1 ->
# 45 "src/lexer.mll"
         ( Lexing.new_line lexbuf; token lexbuf )
# 246 "src/lexer.ml"

  | 2 ->
# 46 "src/lexer.mll"
         ( block_comment lexbuf;   token lexbuf )
# 251 "src/lexer.ml"

  | 3 ->
# 47 "src/lexer.mll"
         ( skip_line lexbuf;       token lexbuf )
# 256 "src/lexer.ml"

  | 4 ->
# 48 "src/lexer.mll"
         ( YaccParser.BR_OPN    )
# 261 "src/lexer.ml"

  | 5 ->
# 49 "src/lexer.mll"
         ( YaccParser.BR_CLS    )
# 266 "src/lexer.ml"

  | 6 ->
let
# 50 "src/lexer.mll"
                           x
# 272 "src/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 50 "src/lexer.mll"
                             ( tokenize_sym x   )
# 276 "src/lexer.ml"

  | 7 ->
let
# 51 "src/lexer.mll"
                           x
# 282 "src/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 51 "src/lexer.mll"
                             ( YaccParser.VAR x )
# 286 "src/lexer.ml"

  | 8 ->
let
# 52 "src/lexer.mll"
                           x
# 292 "src/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 52 "src/lexer.mll"
                             ( tokenize_sym x   )
# 296 "src/lexer.ml"

  | 9 ->
let
# 53 "src/lexer.mll"
                           x
# 302 "src/lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 53 "src/lexer.mll"
                             ( tokenize_num lexbuf x )
# 306 "src/lexer.ml"

  | 10 ->
# 54 "src/lexer.mll"
           ( YaccParser.EOF )
# 311 "src/lexer.ml"

  | 11 ->
let
# 55 "src/lexer.mll"
         x
# 317 "src/lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 55 "src/lexer.mll"
           (
      raise_error lexbuf (InvalidChar x)
    )
# 323 "src/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_token_rec lexbuf __ocaml_lex_state

and block_comment lexbuf =
   __ocaml_lex_block_comment_rec lexbuf 14
and __ocaml_lex_block_comment_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 60 "src/lexer.mll"
         ( Lexing.new_line lexbuf; block_comment lexbuf )
# 335 "src/lexer.ml"

  | 1 ->
# 61 "src/lexer.mll"
         ( () )
# 340 "src/lexer.ml"

  | 2 ->
# 62 "src/lexer.mll"
         (
      raise_error lexbuf EofInComment
    )
# 347 "src/lexer.ml"

  | 3 ->
# 65 "src/lexer.mll"
                 ( block_comment lexbuf )
# 352 "src/lexer.ml"

  | 4 ->
# 66 "src/lexer.mll"
                 ( block_comment lexbuf )
# 357 "src/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_block_comment_rec lexbuf __ocaml_lex_state

and skip_line lexbuf =
   __ocaml_lex_skip_line_rec lexbuf 20
and __ocaml_lex_skip_line_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 69 "src/lexer.mll"
             ( Lexing.new_line lexbuf )
# 369 "src/lexer.ml"

  | 1 ->
# 70 "src/lexer.mll"
             ( () )
# 374 "src/lexer.ml"

  | 2 ->
# 71 "src/lexer.mll"
             ( skip_line lexbuf )
# 379 "src/lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf;
      __ocaml_lex_skip_line_rec lexbuf __ocaml_lex_state

;;
