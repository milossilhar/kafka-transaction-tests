data <- read.csv("size_plot_cluster_msg.csv")

data.text <- round(unlist(data))

ymin <- min(data)
ymax <- max(data)

val <- c(1,2,3,4,5,6)
colors <- rep(c("indianred"), 4)
colors.text <- rep(rep(c("indianred4"), 4), each=6)

pch_1 <- 19
pch_3 <- 15
pch_5 <- 17
pch_9 <- 18

pch_all <- c(pch_1, pch_3, pch_5, pch_9)
pch_legend <- c(pch_1, pch_3, pch_5, pch_9)

matplot(data, 
        #main="",
        xlab="Veľkosť správ", ylab="Rýchlosť posielania producenta [msg/s]",
        xlim=c(1, 6.2), ylim=c(ymin, ymax),
        type="o", pch=pch_all, lty = 1, lwd = 1.3,
        log="y",
        col=colors,
        xaxt="n")
axis(1,at=val,labels=c("50kB", "100kB", "200kB", "500kB", "1MB", "5MB"))
text(rep(val, 3), data.text, data.text, pos=4, col = colors.text, cex=0.9)
legend("bottom", inset=.02, title="Nastavenie producenta", c("Tranzakcie"), col=colors, horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)
legend("bottomleft", inset=.02, title="Veľkosť klastra", c("1", "3", "5", "9"), horiz=TRUE, cex=0.8, pch=pch_legend)

