# LaTeX Document Compilation Guide

## Overview

The file `tables/Sino_Kazakh_Trade_Tables.tex` is a complete LaTeX document that integrates:

- 13 annotated figures (with integrated captions and insights)
- 4 comprehensive statistical tables
- 5 key findings with detailed interpretations
- Full conclusion section

This document is ready for compilation to PDF using any standard LaTeX distribution.

## Document Structure

```
Sino_Kazakh_Trade_Tables.tex
├── Title & Author Info
├── Introduction
├── VISUALIZATIONS (13 annotated figures)
│   ├── Trade Composition (Figures 1-4)
│   ├── Structural Indices (Figures 6-9)
│   ├── 2023 Inflection Analysis (Figures 10-11)
│   └── Bilateral Trade Evolution (Figures 12-14)
├── TABLE 1: Annual Bilateral Trade (2015-2024)
├── TABLE 2: Sectoral Breakdown (Pre-2023 vs Post-2023)
├── TABLE 3: China's Import Penetration by Sector
├── TABLE 4: Summary Comparison
└── Key Findings & Conclusion
```

## Compilation Instructions

### Option 1: Using pdflatex (Command Line)

```bash
cd /Users/akshatsharma/Documents/KazakhIrPapaper/tables

# Compile to PDF
pdflatex -interaction=nonstopmode Sino_Kazakh_Trade_Tables.tex

# If you have references or need to recompile
pdflatex -interaction=nonstopmode Sino_Kazakh_Trade_Tables.tex
pdflatex -interaction=nonstopmode Sino_Kazakh_Trade_Tables.tex
```

Output: `Sino_Kazakh_Trade_Tables.pdf`

### Option 2: Using Overleaf (Cloud-Based)

1. Navigate to https://www.overleaf.com
2. Click "New Project" → "Upload Project"
3. Upload the entire `KazakhIrPapaper` folder
4. Open `tables/Sino_Kazakh_Trade_Tables.tex` in Overleaf
5. Click "Recompile" (Overleaf will compile automatically)
6. Download the PDF from the menu

### Option 3: Using LaTeX IDE (e.g., TexStudio, TexShop)

1. Open `Sino_Kazakh_Trade_Tables.tex` in your LaTeX editor
2. Click "Build" or "Typeset" button
3. PDF will be generated in the same directory

### Option 4: Using online LaTeX compiler

Upload to:

- **Overleaf**: https://www.overleaf.com
- **LaTeX Online**: https://www.latex-online.com/
- **Pastebin + Compiler**: http://www.compileonline.com/execute_latex_online.php

## System Requirements

### Minimum LaTeX Installation

You need:

- `pdflatex` or `xelatex` (included in any TeX distribution)
- Basic LaTeX packages (included by default):
  - `article` (document class)
  - `geometry` (page margins)
  - `booktabs` (professional tables)
  - `float` (figure positioning)
  - `amsmath` (mathematical notation)
  - `graphicx` (image inclusion)
  - `subcaption` (subfigure captions)

### LaTeX Distributions

**macOS:**

```bash
# Using MacTeX
brew install mactex

# Or download from:
# http://www.tug.org/mactex/
```

**Windows:**

- MiKTeX: https://miktex.org/download
- TeXLive: https://tug.org/texlive/

**Linux (Ubuntu/Debian):**

```bash
sudo apt-get install texlive-latex-base
sudo apt-get install texlive-latex-extra
```

## File Organization

The LaTeX compiler expects this directory structure:

```
KazakhIrPapaper/
├── tables/
│   └── Sino_Kazakh_Trade_Tables.tex        ← MAIN FILE
├── figures/
│   ├── fig1_export_composition_annotated.png
│   ├── fig2_import_composition_annotated.png
│   ├── fig3_sectoral_balance_annotated.png
│   ├── fig4_china_penetration_annotated.png
│   ├── fig6_concentration_index_annotated.png
│   ├── fig7_asymmetry_index_annotated.png
│   ├── fig8_vulnerability_multivector_annotated.png
│   ├── fig9_sectoral_penetration_heatmap_annotated.png
│   ├── fig10_2023_structural_shift_annotated.png
│   ├── fig11_hedging_behavior_annotated.png
│   ├── fig12_trade_flows_annotated.png
│   ├── fig13_trade_balance_annotated.png
│   └── fig14_deficit_ratio_annotated.png
```

**Important:** The LaTeX document uses relative paths (`../figures/fig*.png`). If you move files, update the paths in the LaTeX code.

## Troubleshooting

### Error: "File not found: ../figures/fig1_export_composition_annotated.png"

**Solution:** Ensure you're compiling from the `tables/` directory, or adjust the relative path:

- Change `../figures/` to `../../figures/` if compiling from a subdirectory
- Use absolute paths if relative paths don't work: `/Users/akshatsharma/Documents/KazakhIrPapaper/figures/`

### Error: "Package 'graphicx' not found"

**Solution:** Install the full LaTeX distribution:

```bash
# macOS
brew install mactex

# Ubuntu/Debian
sudo apt-get install texlive-latex-extra

# Windows
Download and install MiKTeX from https://miktex.org
```

### Error: "! Undefined control sequence"

**Solution:** Check that all required packages are installed. The preamble requires:

```latex
\usepackage{graphicx}
\usepackage{subcaption}
```

### PDF generated but figures are missing

**Solution:**

1. Check that figure files exist in the `figures/` directory
2. Verify filenames match exactly (case-sensitive on macOS/Linux)
3. Try using absolute paths instead of relative paths
4. Ensure figure files are PNG format and not corrupted

### "BadBox" warnings about overfull/underfull hboxes

**Solution:** This is usually not critical. LaTeX is warning about formatting. If the PDF looks good, you can ignore these warnings.

## Customization

### Changing Figure Size

Edit the `\includegraphics` width in the LaTeX file:

```latex
% Current: 95% of text width
\includegraphics[width=0.95\textwidth]{../figures/fig1_export_composition_annotated.png}

% Alternative sizes:
\includegraphics[width=1\textwidth]{...}   % Full width
\includegraphics[width=0.85\textwidth]{...} % Narrower
\includegraphics[width=6in]{...}            % Fixed width
```

### Adding Captions to Figures

To add captions below figures:

```latex
\begin{figure}[H]
\centering
\includegraphics[width=0.95\textwidth]{../figures/fig1_export_composition_annotated.png}
\caption{Source: Authors' analysis of WITS bilateral trade data (2015-2024)}
\label{fig:exports}
\end{figure}
```

### Changing Page Margins

Edit the geometry package in the preamble:

```latex
\usepackage[margin=0.75in]{geometry}  % Narrower margins
\usepackage[margin=1.5in]{geometry}   % Wider margins
```

### Adjusting Title/Author

Edit the title section:

```latex
\title{Sino-Kazakh Trade Analysis: Structural Shift (2015-2024) \\
       \large With Annotated Visualizations}
\author{Your Name Here}
\date{\today}  % Automatically uses current date
```

## Output Options

### Generate PDF with Bookmarks (Table of Contents)

LaTeX automatically creates a clickable table of contents. The PDF will include:

- Bookmarks for each section
- Hyperlinked cross-references
- Page numbers

### Generate for Print

To optimize for printing:

```latex
% Add to preamble:
\usepackage[pdftex]{hyperref}
\hypersetup{colorlinks=false}  % No colored links for print
```

### Generate for Digital Distribution

To optimize for digital viewing:

```latex
% Add to preamble:
\usepackage{hyperref}
\hypersetup{colorlinks=true, linkcolor=blue}  % Colored links
```

## Final Output

The compilation will generate:

- `Sino_Kazakh_Trade_Tables.pdf` - Final publication-ready document
- `Sino_Kazakh_Trade_Tables.aux` - Auxiliary file (can be deleted)
- `Sino_Kazakh_Trade_Tables.log` - Compilation log (useful for troubleshooting)

## Quick Start

```bash
cd /Users/akshatsharma/Documents/KazakhIrPapaper/tables
pdflatex -interaction=nonstopmode Sino_Kazakh_Trade_Tables.tex
open Sino_Kazakh_Trade_Tables.pdf
```

This will compile the document and open it in your default PDF viewer.

## Quality Assurance

✓ LaTeX document structure is valid
✓ All required packages are standard (no special installation needed)
✓ Relative paths are correct (assuming standard directory structure)
✓ All 13 annotated figures are integrated
✓ All 4 tables are included with proper formatting
✓ Document is publication-ready for PDF output

## Support

If you encounter issues:

1. Check the `.log` file generated during compilation for error details
2. Verify all figure files exist and are readable
3. Test with a simpler document first (e.g., just the title and one section)
4. Use Overleaf for cloud-based compilation if local installation fails
5. Consult LaTeX documentation: https://www.overleaf.com/learn

---

**Document Status:** ✓ Ready for compilation
**Last Updated:** April 16, 2026
**Figures:** 13 annotated visualizations integrated
**Tables:** 4 comprehensive tables with Kazakhstan-centric perspective
