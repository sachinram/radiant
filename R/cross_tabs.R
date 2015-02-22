#' Evaluate associations between categorical variables
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/cross_tabs.html} for an example in Radiant
#'
#' @param dataset Dataset name (string). This can be a dataframe in the global environment or an element in an r_data list from Radiant
#' @param ct_var1 A categorical variable
#' @param ct_var2 Another categorical variable
#' @param data_filter Expression entered in, e.g., Data > View to filter the dataset in Radiant. The expression should be a string (e.g., "price > 10000")
#' @param ct_observed Show the observed frequencies table for variables `ct_var1` and `ct_var2`
#' @param ct_expected Show the expected frequencies table (i.e., frequencies if the null hypothesis holds)
#' @param ct_contrib Show the contribution to the overall chi-squared statistic for each cell (i.e., (o - e)^2 / e)
#' @param ct_std_residuals Show standardized differences between the observed and expected frequencies
#' @param ct_deviation Show the percentage difference between the observed and expected frequencies
#'
#' @return A list with all variables defined in the function as an object of class compare_props
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#'
#' @seealso \code{\link{summary.compare_props}} to summarize results
#' @seealso \code{\link{plot.compare_props}} to plot results
#'
#' @export
cross_tabs <- function(dataset, ct_var1, ct_var2,
                     	data_filter = "",
                     	ct_observed = TRUE,
                     	ct_expected = FALSE,
                     	ct_contrib = FALSE,
                     	ct_std_residuals = FALSE,
                     	ct_deviation = FALSE) {

	dat <- getdata_exp(dataset, c(ct_var1, ct_var2), filt = data_filter)

	dnn = c(paste("Group(",ct_var1,")",sep = ""), paste("Variable(",ct_var2,")",sep = ""))
	tab <- table(dat[,ct_var1], dat[,ct_var2], dnn = dnn)
	cst <- suppressWarnings( chisq.test(tab, correct = FALSE) )

	# dat not needed in summary or plot
	rm(dat)

	# adding the % deviation table
	o <- cst$observed
	e <- cst$expected
	cst$deviation <- (o-e) / e

	nrPlot <- sum(c(ct_observed, ct_expected, ct_deviation, ct_std_residuals))
	plot_width = 650
	plot_height = 400 * nrPlot

  environment() %>% as.list %>% set_class(c("cross_tabs",class(.)))
}

# test
# library(broom)
# library(tidyr)
# library(dplyr)
# source("~/gh/radiant_dev/R/radiant.R")
# result <- cross_tabs("diamonds","cut","clarity")

#' Summarize method for output from the cross_tabs function. This is a method of class cross_tabs and can be called as summary or summary.cross_tabs
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/cross_tabs.html} for an example in Radiant
#'
#' @examples
#' result <- cross_tabs("titanic", "pclass", "survived")
#' summary(result)
#'
#' @seealso \code{\link{cross_tabs}} to calculate results
#' @seealso \code{\link{plot.cross_tabs}} to plot results
#'
#' @export
summary.cross_tabs <- function(result) {

  cat("Cross-tabs\n")
	cat("Data     :", result$dataset, "\n")
	if(result$data_filter %>% gsub("\\s","",.) != "")
		cat("Filter   :", gsub("\\n","", result$data_filter), "\n")
	cat("Variables:", paste0(c(result$ct_var1, result$ct_var2), collapse=", "), "\n")
	cat("Null hyp.: there is no association between", result$ct_var1, "and", result$ct_var2, "\n")
	cat("Alt. hyp.: there is an association between", result$ct_var1, "and", result$ct_var2, "\n")

	result$cst$observed %>% rownames %>% c(., "Total") -> rnames
	result$cst$observed %>% colnames %>% c(., "Total") -> cnames

	if(result$ct_observed) {
		cat("\nObserved values:\n")
		result$cst$observed %>%
			rbind(colSums(.)) %>%
			set_rownames(rnames) %>%
			cbind(rowSums(.)) %>%
			set_colnames(cnames) %>%
			print
	}
	if(result$ct_expected) {
		cat("\nExpected values:\n")
		result$cst$expected %>%
			rbind(colSums(.)) %>%
			set_rownames(rnames) %>%
			cbind(rowSums(.)) %>%
			set_colnames(cnames) %>%
			round(2) %>%
			print
	}
	if(result$ct_contrib) {
		cat("\nContribution to chisquare value:\n")
		# print((result$cst$observed - result$cst$expected)^2 / result$cst$expected, digits = 2)
		((result$cst$observed - result$cst$expected)^2 / result$cst$expected) %>%
			rbind(colSums(.)) %>%
			set_rownames(rnames) %>%
			cbind(rowSums(.)) %>%
			set_colnames(cnames) %>%
			round(2) %>%
			print
	}
	if(result$ct_std_residuals) {
		cat("\nDeviation (standardized):\n")
		print(round(result$cst$residuals, 2)) 	# these seem to be the correct std.residuals
	}
	if(result$ct_deviation) {
		cat("\nDeviation (percentage):\n")
		print(round(result$cst$deviation, 2)) 	# % deviation
	}
	# if(result$ct_cellperc) {
	# 	cat("\nCell percentages:\n")
	# 	print(prop.table(result$table), digits = 2)  	# cell percentages
	# }
	# if(result$ct_rowperc) {
	# 	cat("\nRow percentages:\n")
	# 	print(prop.table(result$table, 1), digits = 2) # row percentages
	# }
	# if(result$ct_colperc) {
	# 	cat("\nColumn percentages:\n")
	# 	print(prop.table(result$table, 2), digits = 2) # column percentages
	# }

	result$cst %>% tidy %>% round(3) -> res
	if(res$p.value < .001) res$p.value  <- "< .001"
	cat(paste0("\nChi-squared: ", res$statistic, " df(", res$parameter, "), p.value ", res$p.value), "\n\n")

	cat(paste(sprintf("%.1f",100 * (sum(result$cst$expected < 5) / length(result$cst$expected))),"% of cells have expected values below 5\n\n"), sep = "")
}

#' Plot results from the cross_tabs function. This is a method of class cross_tabs and can be called as plot or plot.cross_tabs
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/cross_tabs.html} for an example in Radiant
#'
#' @examples
#' result <- cross_tabs("titanic", "pclass", "survived", cp_plots = "props")
#' plot(result)
#'
#' @seealso \code{\link{cross_tabs}} to calculate results
#' @seealso \code{\link{summary.cross_tabs}} to summarize results
#'
#' @export
plot.cross_tabs <- function(result) {

	gather_table <- function(tab) {
		tab %>%
			data.frame %>%
			mutate(rnames = rownames(.)) %>%
			gather_("variable", "values")
	}

	plots <- list()
	if(result$ct_std_residuals) {

		tab <- gather_table(result$cst$residuals)
		colnames(tab)[1:2] <- c(result$ct_var1, result$ct_var2)
		plots[['residuals']] <- ggplot(tab, aes_string(x = result$ct_var1, y = "values", fill = result$ct_var2)) +
         			geom_bar(stat="identity", position = "dodge", alpha = .7) +
     					geom_hline(yintercept = c(-1.96,1.96,-1.64,1.64), color = 'black', linetype = 'longdash', size = .5) +
     					geom_text(data = NULL, x = 1, y = 2.11, label = "95%") +
     					geom_text(data = NULL, x = 1, y = 1.49, label = "90%") +
         			labs(list(title = paste("Deviation (standardized) for ",result$ct_var2," versus ",result$ct_var1, sep = ""), x = result$ct_var1))
	}

	if(result$ct_deviation) {

		tab <- gather_table(result$cst$deviation)
		colnames(tab)[1:2] <- c(result$ct_var1, result$ct_var2)
		plots[['deviation']] <- ggplot(tab, aes_string(x = result$ct_var1, y = "values", fill = result$ct_var2)) +
         			geom_bar(stat="identity", position = "dodge", alpha = .7) + ylim(-1,1) +
         			labs(list(title = paste("Deviation (percentage) for ",result$ct_var2," versus ",result$ct_var1, sep = ""), x = result$ct_var1))
	}

	if(result$ct_expected) {

		fact_names <- result$cst$expected %>% dimnames %>% as.list
  	tab <- gather_table(result$cst$expected)
		tab$rnames %<>% as.factor %>% factor(levels = fact_names[[1]])
		tab$variable %<>% as.factor %>% factor(levels = fact_names[[2]])

		plots[['expected']] <- ggplot(tab, aes_string(x = "rnames", y = "values", fill = "variable")) +
         			geom_bar(stat="identity", position = "fill", alpha = .7) +
         			labs(list(title = paste("Expected values for ",result$ct_var2," versus ",result$ct_var1, sep = ""),
							x = "", y = "", fill = result$ct_var2))
	}

	if(result$ct_observed) {

		fact_names <- result$cst$observed %>% dimnames %>% as.list
  	tab <- gather_table(result$cst$observed)
		colnames(tab)[1:2] <- c(result$ct_var1, result$ct_var2)
		tab$result$ct_var1 %<>% as.factor %>% factor(levels = fact_names[[1]])
		tab$result$ct_var1 %<>% as.factor %>% factor(levels = fact_names[[2]])

		plots[['stacked']] <-
		ggplot(tab, aes_string(x = result$ct_var1, y = "values", fill = result$ct_var2)) +
         			geom_bar(stat="identity", position = "fill", alpha = .7) +
         			labs(list(title = paste("Observed values for ",result$ct_var2," versus ",result$ct_var1, sep = ""),
							x = "", y = "", fill = result$ct_var2))
	}

	sshh( do.call(grid.arrange, c(plots, list(ncol = 1))) )
}