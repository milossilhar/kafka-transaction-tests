data <- read.csv("producer_plot_overall.csv")

ymin <- min(data)
ymax <- max(data) + 25000

colors <- c("seagreen4","royalblue","indianred")

pch_1 <- 19
pch_3 <- 15
pch_5 <- 17
pch_9 <- 18

pch_all <- c(rep(pch_1,3), rep(pch_3,3), rep(pch_5,3), rep(pch_9,3))
pch_legend <- c(pch_1, pch_3, pch_5, pch_9)

matplot(data, 
        #main="",
        #sub="",
        xlab="Rozdelenie do tém", ylab="Rýchlosť posielania producenta [msg/s]",
        xlim=c(1, 5), ylim=c(ymin, ymax),
        type="o", pch=pch_all, lty = 1, lwd = 1.3,
        col=colors,
        xaxt="n")
axis(1,at=c(1,2,3,4,5),labels=c("1-0-0 [1]", "2-0-1 [3]", "5-1-2 [8]", "10-2-4 [16]", "50-10-20 [80]"))
legend("topleft", inset=.02, title="Nastavenie producenta", c("ACKS=all","ACKS=1","Tranzakcie"), col=colors, horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)
legend("topright", inset=.02, title="Veľkosť klastra", c("1", "3", "5", "9"), horiz=TRUE, cex=0.8, pch=pch_legend)

