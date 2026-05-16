module Main where

import System.Environment (getArgs)
import System.FilePath (replaceExtension, dropExtension)
import System.Process (callProcess)
import MarkTex.Parser
import MarkTex.Render.LaTeX

main :: IO ()
main = do
  args <- getArgs

  case args of
    -- Only input provided -> derive output filename
    [inputFile] -> do
      let outputFile = replaceExtension inputFile "tex"
      process inputFile outputFile

    -- Output provided
    [inputFile, outputFile] ->
      process inputFile outputFile

    _ ->
      putStrLn "Usage: runghc Main.hs <input.md> [output.tex]"

process :: FilePath -> FilePath -> IO ()
process inputFile outputFile = do
  parsed <- parseDocumentFromFile inputFile

  case parsed of
    Left err ->
      putStrLn ("Parse error: " ++ err)

    Right ast ->
      case renderDocument ast of
        Left err ->
          putStrLn ("Render error: " ++ err)

        Right latex -> do
          writeFile outputFile latex
          putStrLn ("Written to " ++ outputFile)

          compileLatexWithBibliography outputFile

compileLatexWithBibliography :: FilePath -> IO ()
compileLatexWithBibliography texFile = do
  let baseName = dropExtension texFile
  let pdfFile = baseName ++ ".pdf"

  putStrLn "Compiling LaTeX..."

  callProcess "pdflatex" ["-interaction=nonstopmode", texFile]

  putStrLn "Running BibTeX..."

  callProcess "bibtex" [baseName]

  putStrLn "Recompiling LaTeX..."

  callProcess "pdflatex" ["-interaction=nonstopmode", texFile]
  callProcess "pdflatex" ["-interaction=nonstopmode", texFile]

  putStrLn ("PDF generated: " ++ pdfFile)