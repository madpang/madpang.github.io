#! /usr/bin/env pwsh -NoProfile
<#
	@brief: Build a full HTML page of a post from a custom plain text markup.

	@details:
	1. Read the template HTML file.
	2. Use the mmd2html tool to convert the source text to HTML, and insert it into the anchor point in the template.
	3. Write the output to the target HTML file.

	@author
	- madpang

	@date:
	- Created on 2025-05-18
	- Updated on 2025-05-18
#>

param(
	[Parameter(Mandatory = $True, Position = 1)][string]$path2html,
	[Parameter(Mandatory = $True, Position = 2)][string]$path2txt,
	[Parameter(Mandatory = $True, Position = 3)][string]$path2html_template
)

$converter = "./tools/mmd2html/mmd2html"

# === Convert the source text to HTML
$formatted_lines = (& $converter $path2txt)

# === Read the template HTML file
$t_lines = Get-Content -Path $path2html_template

# === Initialize the output HTML
$out_lines = @()

# === Processing
$inBlockComment = $false
for ($ii = 0; $ii -lt $t_lines.Count; $ii++) {
	$line = $t_lines[$ii]
	# Check if the line is a block comment start, assuming only world character, `@`, and `:` are allowed
	if ($line -match "<!--\s*(?<id>[@:\w]+)\s*$") {
		$inBlockComment = $true
		$id = $Matches['id']
		if ($id -eq "@ANCHOR:NULL") {
			$out_lines += '<!-- @note: This file is auto-generated. MANUAL EDITS WILL BE LOST -->'
		}
		continue
	}
	if ($line -eq '-->') {
		$inBlockComment = $false
		continue
	}
	if ($inBlockComment) {
		# Skip the block comment
		continue
	}
	if ($line -match "^<!--\s*@ANCHOR:ARTICLE\s*-->$") {
		# Insert the formatted lines into the anchor point
		$out_lines += $formatted_lines
	} else {
		# Add the line to the output
		$out_lines += $line
	}
}

# === Write the output to HTML file
Set-Content -Path $path2html -Value $out_lines -Encoding utf8
