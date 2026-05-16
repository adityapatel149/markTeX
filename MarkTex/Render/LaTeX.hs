module MarkTex.Render.LaTeX
  ( renderDocument
  , collectLabels
  , validateReferences
  ) where

import qualified Data.Map as M
import Data.List (intercalate)
import MarkTex.AST

-- =========================
-- Label Collection
-- =========================

type LabelTable = M.Map Label Block

collectLabels :: Document -> Either String LabelTable
collectLabels doc = goBlocks M.empty (docBlocks doc)
  where
    goBlocks table [] = Right table
    goBlocks table (b:bs) = do
      table' <- goBlock table b
      goBlocks table' bs

    goBlock table block =
      case block of
        Header _ _ Nothing ->
          Right table

        Header _ _ (Just lbl) ->
          if M.member lbl table
            then Left ("Duplicate label: " ++ lbl)
            else Right (M.insert lbl block table)

        Paragraph _ ->
          Right table

        CodeBlock _ ->
          Right table

        UnorderedList items ->
          foldl
            (\acc item -> acc >>= \t -> goBlocks t item)
            (Right table)
            items

-- =========================
-- Reference Validation
-- =========================

validateReferences :: LabelTable -> Document -> Either String ()
validateReferences table doc = mapM_ (checkBlock table) (docBlocks doc)

checkBlock :: LabelTable -> Block -> Either String ()
checkBlock table block =
  case block of
    Paragraph xs ->
      mapM_ (checkInline table) xs

    Header _ xs _ ->
      mapM_ (checkInline table) xs

    CodeBlock _ ->
      Right ()

    UnorderedList items ->
      mapM_ (mapM_ (checkBlock table)) items

checkInline :: LabelTable -> Inline -> Either String ()
checkInline table inline =
  case inline of
    Plain _       -> Right ()
    Italic xs     -> mapM_ (checkInline table) xs
    Bold xs       -> mapM_ (checkInline table) xs
    Underline xs  -> mapM_ (checkInline table) xs
    Strike xs     -> mapM_ (checkInline table) xs
    Citation _    -> Right ()
    Reference xs lbls ->
      mapM_ (checkInline table) xs >>
      mapM_
        (\lbl -> 
          if M.member lbl table
            then Right ()
            else Left ("Undefined reference: " ++ lbl)
        )
      lbls
-- =========================
-- Rendering to LaTeX
-- =========================

renderDocument :: Document -> Either String String
renderDocument doc = do
  table <- collectLabels doc
  validateReferences table doc
  pure $
    unlines
      [ "\\documentclass{article}"
      , "\\usepackage[utf8]{inputenc}"
      , "\\usepackage{hyperref}"
      , "\\usepackage{cleveref}"
      , "\\usepackage[margin=1in]{geometry}"
      , "\\usepackage[normalem]{ulem}"   -- for \\sout
      , ""
      , renderMeta doc
      , ""
      , "\\begin{document}"
      , ""
      , renderMakeTitle doc
      , renderBlocks doc
      , ""
      , "\\bibliographystyle{plain}"
      , "\\bibliography{references}"
      , "\\end{document}"
      ]


renderMeta :: Document -> String
renderMeta doc =
  concat
    [ maybe "" (\t -> "\\title{"  ++ renderInlines t ++ "}\n") (docTitle doc)
    , maybe "" (\a -> "\\author{" ++ renderInlines a ++ "}\n") (docAuthor doc)
    , maybe "" (\d -> "\\date{"   ++ renderInlines d ++ "}\n") (docDate doc)
    ]

renderMakeTitle :: Document -> String
renderMakeTitle doc =
  if anyPresent then "\\maketitle\n\n" else ""
  where
    anyPresent =
      docTitle doc /= Nothing ||
      docAuthor doc /= Nothing ||
      docDate doc /= Nothing

renderBlocks :: Document -> String
renderBlocks doc = concatMap renderBlock (docBlocks doc)

renderBlock :: Block -> String
renderBlock block =
  case block of
    Paragraph xs ->
      renderInlines xs ++ "\n\n"

    Header level xs mLabel ->
      headerCommand level
        ++ "{"
        ++ renderInlines xs
        ++ "}"
        ++ renderLabel mLabel
        ++ "\n\n"

    UnorderedList items ->
      "\\begin{itemize}\n"
      ++ concatMap renderItem items
      ++ "\\end{itemize}\n\n"

    CodeBlock code ->
      "\\begin{verbatim}\n"
      ++ code
      ++ "\n\\end{verbatim}\n\n"
  where
    renderItem :: [Block] -> String
    renderItem bs =
      "\\item " ++ trimTrailingNewlines (concatMap renderBlock bs) ++ "\n"

renderLabel :: Maybe Label -> String
renderLabel Nothing      = ""
renderLabel (Just label) = "\\label{" ++ escapeLatex label ++ "}"

headerCommand :: Int -> String
headerCommand n =
  case n of
    1 -> "\\section"
    2 -> "\\subsection"
    3 -> "\\subsubsection"
    4 -> "\\paragraph"
    _ -> "\\subparagraph"

renderInlines :: [Inline] -> String
renderInlines = concatMap renderInline

renderInline :: Inline -> String
renderInline inline =
  case inline of
    Plain s ->
      escapeLatex s

    Italic xs ->
      "\\textit{" ++ renderInlines xs ++ "}"

    Bold xs ->
      "\\textbf{" ++ renderInlines xs ++ "}"

    Underline xs ->
      "\\underline{" ++ renderInlines xs ++ "}"

    Strike xs ->
      "\\sout{" ++ renderInlines xs ++ "}"

    Citation keys ->
      "\\cite{" ++ intercalate "," keys ++ "}"

    Reference xs lbls ->
      let cref = "\\Cref{" ++ intercalate "," (map escapeLatex lbls) ++ "}"
      in case (xs, lbls) of
        (_, []) -> ""
        ([], _) -> cref
        _ ->
          "\\hyperref[" ++ escapeLatex (head lbls) ++ "]{"
          ++ renderInlines xs
          ++ "} (" ++ cref ++ ")"

-- =========================
-- Utilities
-- =========================

escapeLatex :: String -> String
escapeLatex = concatMap escapeChar
  where
    escapeChar :: Char -> String
    escapeChar c =
      case c of
        '#'  -> "\\#"
        '$'  -> "\\$"
        '%'  -> "\\%"
        '&'  -> "\\&"
        '_'  -> "\\_"
        '{'  -> "\\{"
        '}'  -> "\\}"
        '['  -> "{[}"
        ']'  -> "{]}"
        '~'  -> "\\textasciitilde{}"
        '^'  -> "\\textasciicircum{}"
        '\\' -> "\\textbackslash{}"
        _    -> [c]

trimTrailingNewlines :: String -> String
trimTrailingNewlines = reverse . dropWhile (== '\n') . reverse
