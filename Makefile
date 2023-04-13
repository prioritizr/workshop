all: clean data test pdf site

clean:
	@rm -rf _book
	@rm -rf _bookdown_files

clean_temp:
	@rm -f prioritizr-workshop-manual.Rmd
	@rm -f prioritizr-workshop-manual-teaching.Rmd

site: clean_temp
	Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::gitbook')"

pdf: clean_temp
	Rscript -e "bookdown::render_book('index.Rmd', 'bookdown::pdf_book')"
	rm -f prioritizr-workshop-manual.log
	rm -f prioritizr-workshop-manual.toc
	rm -f prioritizr-workshop-manual.tex

check:
	R -e "source('verify-solutions.R')"
	rm -f Rplots.pdf

.PHONY: data clean check website site data
