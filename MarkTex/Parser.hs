module MarkTex.Parser
  ( parseDocument
  , parseDocumentFromFile
  ) where

import MarkTex.AST
import Text.ParserCombinators.Parsec
import System.Environment
import Data.List

-- Top-level file parser
documentParser :: GenParser Char st Document
documentParser = do
  many newline
  (title, author, date) <- metaParser
  blocks <- many blockParser
  many newline
  eof
  return $ Document title author date blocks


-- Metadata Parser
metaParser :: GenParser Char st (Maybe [Inline], Maybe [Inline], Maybe [Inline])
metaParser = do
  metas <- many metaLine
  many newline 
  return (lookupMeta "Title" metas,
          lookupMeta "Author" metas,
          lookupMeta "Date" metas)

metaLine :: GenParser Char st (String, [Inline])
metaLine = do
  char '%'
  hspaces
  key <- many1 letter
  char ':'
  hspaces
  content <- manyTill inlineParser newline
  return (key, content)

lookupMeta :: String -> [(String, [Inline])] -> Maybe [Inline]
lookupMeta key xs = lookup key xs

-- Block parser
blockParser :: GenParser Char st Block
blockParser = 
      try headerParser
  <|> try listParser
  <|> try codeParser
  <|> try paragraphParser
  <?> "block"


-- Paragraph [Inline]
-- Current placeholder: reads one paragraph until blank line or EOF
paragraphParser :: GenParser Char st Block
paragraphParser = do
  inlines <- many1 inlineParser
  optional paragraphEnd
  return $ Paragraph inlines


-- Header Int [Inline] (Maybe Label)
headerParser :: GenParser Char st Block
headerParser = do
  level <- length <$> many1 (char '#')
  hspaces
  inlines <- many1 inlineParser
  mLabel <- optionMaybe labelParser
  optional (many1 newline)
  return $ Header level inlines mLabel


-- Parse Labels
labelParser :: GenParser Char st Label
labelParser = do
  hspaces
  string "{#"
  lbl <- labelName
  char '}'
  return lbl


-- UnorderedList [[Block]]
listParser :: GenParser Char st Block
listParser = do
  items <- many1 itemParser
  return $ UnorderedList items

-- Parser List items
itemParser :: GenParser Char st [Block]
itemParser = do
  char '-'
  hspaces
  firstInlines <- many1 inlineParser
  optional (many1 newline)
  nested <- many indentedBlockParser
  return (Paragraph firstInlines : nested)

-- Include indented blocks inside list item
indentedBlockParser :: GenParser Char st Block
indentedBlockParser = do
  try indentation
  blockParser

indentation :: GenParser Char st ()
indentation = do
  count 2 (char ' ')
  return ()


-- CodeBlock String (for code or verbatim)
codeParser :: GenParser Char st Block
codeParser = do
  string "```"
  optional newline
  content <- manyTill anyChar (try (string "```"))
  optional (many1 newline)
  return $ CodeBlock content





-- Inline Parser
-- Later you can add:
--   boldParser <|> italicParser <|> underline, strike, citationParser <|> referenceParser <|> plainParser
inlineParser :: GenParser Char st Inline
inlineParser =
      try boldParser
  <|> try italicParser
  <|> try underlineParser
  <|> try strikeParser
  <|> try citationParser
  <|> try referenceParser
  <|> try escapedCharParser
  <|> try plainParser
  <?> "inline"


-- Bold [Inline]
boldParser :: GenParser Char st Inline
boldParser = do
  string "**"
  inlines <- manyTill inlineParser boldEnd
  return $ Bold inlines

boldEnd :: GenParser Char st String
boldEnd = try $ do
  notFollowedBy (string "***")
  string "**"


-- Italic [Inline]
italicParser :: GenParser Char st Inline
italicParser = do
  char '*'
  inlines <- manyTill inlineParser italicEnd
  return $ Italic inlines

italicEnd :: GenParser Char st Char
italicEnd =
      try normalItalicEnd
  <|> try italicBeforeBoldEnd

normalItalicEnd :: GenParser Char st Char
normalItalicEnd = do
  char '*'
  notFollowedBy (char '*')
  return '*'

italicBeforeBoldEnd :: GenParser Char st Char
italicBeforeBoldEnd = do
  char '*'
  lookAhead (string "**")
  return '*'


-- Underline [Inline]
underlineParser :: GenParser Char st Inline
underlineParser = do
  char '_'
  inlines <- manyTill inlineParser (try (char '_'))
  return $ Underline inlines


-- Strike [Inline]
strikeParser :: GenParser Char st Inline
strikeParser = do
  string "~~"
  inlines <- manyTill inlineParser (try (string "~~"))
  return $ Strike inlines


-- Citation CitationKey
citationParser :: GenParser Char st Inline
citationParser = do
  string "[@"
  keys <- citationKey `sepBy1` comma
  char ']'
  return $ Citation keys

citationKey :: GenParser Char st CitationKey
citationKey =
  many1 (alphaNum <|> char '_' <|> char '-' <|> char ':')


-- Reference [Inline] Label
referenceParser :: GenParser Char st Inline
referenceParser = do
  char '['
  inlines <- many inlineParser
  char ']'
  hspaces
  string "(#"
  labels <- labelName `sepBy1` comma 
  char ')'
  return $ Reference inlines labels


-- Escaped characters parser
escapedCharParser :: GenParser Char st Inline
escapedCharParser = do
  char '\\'
  c <- oneOf "#$%&_{}~^\\[]/*"
  return $ Plain [c]


-- Plain String
-- Add [] when you implement citations and links
plainParser :: GenParser Char st Inline
plainParser = do
  txt <- many1 (noneOf "\n\\{}[]*_~")
  return $ Plain txt







labelName :: GenParser Char st Label
labelName =
  many1 (alphaNum <|> char '_' <|> char ':' <|> char '-')

comma :: GenParser Char st Char
comma = do
  hspaces
  c <- char ','
  hspaces
  return c

-- Paragraph ends on one or more newlines for now.
-- Later you may want exactly blank lines: "\n\n"
paragraphEnd :: GenParser Char st ()
paragraphEnd = do
  many1 newline
  return ()

hspaces :: GenParser Char st String
hspaces = many (oneOf " \t")





-- Public API
parseDocument :: String -> Either String Document
parseDocument input =
  case parse documentParser "(input)" input of
    Left err  -> Left (show err)
    Right doc -> Right doc


parseDocumentFromFile :: FilePath -> IO (Either String Document)
parseDocumentFromFile path = do
  contents <- readFile path
  pure (parseDocument contents)