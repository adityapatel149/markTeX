% Title: My ~~Complex~~ **_*Simple*_ Paper**
% Author: \~John\_Doe
% Date: 2026

Hello from my mini markTeX parser with escaped LaTeX characters:
\# \$ \% \& \_ \{ \} \~ \^ \\ \/ \[ \] !!

# Introduction {#sec:intro}

This is *italic*, **bold**, _underline_, ~~strike~~, **start bold with *italic and _underline and ~~strike~~ inside_ inside*.** Lets take a look at all our features down below.


New paragraph showing Nested formatting:

- First list item with References: See [](#sec:intro) and the [features section](#sec:features) and also see [these sections](#sec:intro,sec:background, sec:list-header). 

- [@paper1, paper_2026] and [@paper1] mixed with formatting *italic [@paper1, paper_2026]*.

- Third list item with nesting
  Second paragraph inside third item
  ## Header inside list item {#sec:list-header}
  More text after header


Paragraph outside the list.

# Background {#sec:background}
Something about the background of the project, it was motivated to bring markdown's simplicity to LaTeX's complex structure and powerful features.

## Features {#sec:features}
Some features are mentioned above already. Now lets do a code block test:
```
print("Hello, MarkTex!")
# Not parsed as markdown
**not bold** , *not italic* , _not underline_ , ~~not strike~~
[@not_a_citation] , [#not a reference]
```
End of document.
