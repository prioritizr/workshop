# create temporary directory
td <- file.path(tempdir(), basename(tempfile()))
dir.create(td, showWarnings = TRUE, recursive = TRUE)

# find Rmd files
src_rmd_paths <- dir(".", "^.*\\.Rmd", full.names = TRUE)
src_rmd_paths <- src_rmd_paths[basename(src_rmd_paths) != "index.Rmd"]
src_rmd_paths <- c(file.path(getwd(), "index.Rmd"), src_rmd_paths)

# file names for copied Rmd files
tmp_rmd_paths <- file.path(td, basename(src_rmd_paths))

# copy Rmd files to temporary directory
file.copy(src_rmd_paths, tmp_rmd_paths)

# iterate over text in Rmd files and remove block2 chunks and replace
# specify that code in back ticks should be treated as code
# i.e. convert `print(1)` to `r print(1)`
result <- sapply(tmp_rmd_paths, function(x) {
  ## ingest rmarkdown file
  r <- readLines(x)
  ## find block2 chunks
  b2_line_idx <- which(startsWith(r, "```{block2") & grepl("rmdanswer", r))
  if (length(b2_line_idx) == 0)
    return(FALSE)
  ## find backticks
  all_backticks_idx <- which(r == "```")
  b2_backticks <- numeric(length(b2_line_idx))
  for (i in seq_along(b2_line_idx)) {
    ### remove backticks before the b2 line
    j <- all_backticks_idx[all_backticks_idx > b2_line_idx[i]]
    ### find nearest backtick
    b2_backticks[i] <- min(j)
  }
  ## convert inline chunks without r inside the backtick region to
  ## inline r chunks
  for (i in seq_along(b2_line_idx)) {
    curr_idx <- seq(b2_line_idx[i] + 1, b2_backticks[i] - 1)
    r[curr_idx] <- sapply(r[curr_idx], sub, pattern = "`",
                          replacement = "`r ", fixed = TRUE,
                          USE.NAMES = FALSE)
  }
  ## remove b2 lines and their backticks
  r <- r[-1 * c(b2_line_idx, b2_backticks)]
  ## save result
  writeLines(r, x)
  ## return success
  TRUE
})

# purl R code
options(knitr.purl.inline = TRUE)
tmp_r_paths <- gsub(".Rmd", ".R", tmp_rmd_paths, fixed = TRUE)
for (i in seq_along(tmp_rmd_paths))
  knitr::purl(tmp_rmd_paths[i], output = tmp_r_paths[i])

# execute R code
for (i in seq_along(tmp_r_paths)) {
  cat(paste0("############# ", basename(tmp_r_paths[i]) , " #############\n"))
  source(tmp_r_paths[i])
}

# delete temporary files
unlink(td, force = TRUE)
