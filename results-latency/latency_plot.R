data <- read.csv("latency_plot.csv")

ymin <- min(data)
ymax <- max(data) + 1

pch_1 <- 19
pch_3 <- 15
pch_5 <- 17
pch_9 <- 18

pch_all <- c(rep(pch_1,3), rep(pch_3,3), rep(pch_5,3), rep(pch_9,3))
pch_legend <- c(pch_1, pch_3, pch_5, pch_9)

matplot(data, 
     main="Priemerný čas oneskorenia konzumenta",
     xlab="", ylab="Priemerné oneskorenie [ms]",
     xlim=c(1, 3), ylim=c(ymin, ymax),
     type="o", pch=pch_all, lty = 1, lwd = 1.3,
     col=topo.colors(9),
     xaxt="n")
axis(1,at=c(1,2,3),labels=c("Beh 1.", "Beh 2.", "Beh 3."))
legend("topleft", inset=.02, title="Nastavenie producenta", c("ACKS=all","ACKS=1","Tranzakcie"), col=topo.colors(9), horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)
legend("topright", inset=.02, title="Veľkosť klastra", c("1", "3", "5", "9"), horiz=TRUE, cex=0.8, pch=pch_legend)
