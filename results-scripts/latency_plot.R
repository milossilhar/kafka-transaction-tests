data <- read.csv("latency_plot.csv")

data.text <- round(unlist(data), 2)

NUMBER_OF_RUNS <- nrow(data)

ymin <- min(data)
ymax <- max(data)

colors <- c("seagreen4","royalblue","indianred")
colors.text <- rep(colors, each=NUMBER_OF_RUNS)

x.values <- c(1:NUMBER_OF_RUNS)
axis.text <- sprintf("Beh %d.", x.values)

pch_1 <- 19
pch_3 <- 15
pch_5 <- 17
pch_9 <- 18

pch_all <- c(rep(pch_1,NUMBER_OF_RUNS), rep(pch_3,NUMBER_OF_RUNS), rep(pch_5,NUMBER_OF_RUNS), rep(pch_9,NUMBER_OF_RUNS))
pch_legend <- c(pch_1, pch_3, pch_5, pch_9)

matplot(data, 
     #main="Priemerný čas oneskorenia konzumenta",
     xlab="", ylab="Priemerné oneskorenie [ms]",
     xlim=c(1, NUMBER_OF_RUNS), ylim=c(ymin, ymax),
     type="o", pch=pch_all, lty = 1, lwd = 1.3,
     col=colors,
     xaxt="n")
axis(1,at=x.values,labels=axis.text)
text(x.values, data.text, data.text, pos=3, col = colors.text, cex=0.8)
legend("topleft", inset=.02, title="Nastavenie producenta", c("ACKS=all","ACKS=1","Tranzakcie"), col=colors, horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)
legend("topright", inset=.02, title="Veľkosť klastra", c("1", "3", "5", "9"), horiz=TRUE, cex=0.8, pch=pch_legend)
