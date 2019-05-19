data <- read.csv("size_plot_acks_msg.csv")

data.text <- round(unlist(data))

ymin <- min(data)
ymax <- max(data) + 500

val <- c(1,2,3,4,5,6)
colors <- c("seagreen4","royalblue","indianred")
colors.text <- rep(colors, each=6)

pch_3 <- 15

pch_all <- c(rep(pch_3,3))
pch_legend <- c(pch_3)

matplot(data, 
        #main="",
        xlab="Veľkosť správ", ylab="Rýchlosť posielania producenta [msg/s]",
        xlim=c(1, 6), ylim=c(ymin, ymax),
        type="o", pch=pch_all, lty = 1, lwd = 1.3,
        col=colors,
        log="y",
        xaxt="n")
axis(1,at=val,labels=c("50kB", "100kB", "200kB", "500kB", "1MB", "5MB"))
text(rep(val, 3), data.text, data.text, pos=3, col = colors.text, cex=0.9)
legend("topright", inset=.02, title="Nastavenie producenta", c("ACKS=all","ACKS=1","Tranzakcie"), col=colors, horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)
legend("top", inset=.02, title="Veľkosť klastra", c("3"), horiz=TRUE, cex=0.8, pch=pch_legend)

