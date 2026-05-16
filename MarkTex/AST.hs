
-- =========================
-- AST Definitions
-- =========================
module MarkTex.AST
  ( Label
  , CitationKey
  , Document(..)
  , Block(..)
  , Inline(..)
  ) where

type Label = String
type CitationKey = String

data Document = Document
  { docTitle  :: Maybe [Inline]
  , docAuthor :: Maybe [Inline]
  , docDate   :: Maybe [Inline]
  , docBlocks :: [Block]
  }
  deriving (Show, Eq)

data Block
  = Paragraph [Inline]
  | Header Int [Inline] (Maybe Label)
  | UnorderedList [[Block]]
  | CodeBlock String
  deriving (Show, Eq)

data Inline
  = Plain String
  | Italic [Inline]
  | Bold [Inline]
  | Underline [Inline]
  | Strike [Inline]
  | Citation [CitationKey]
  | Reference [Inline] [Label]
  deriving (Show, Eq)