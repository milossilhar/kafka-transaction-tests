data <- read.csv("producer_plot_acks.csv")

ymin <- min(data)
ymax <- max(data) + 5000

data.text <- round(unlist(data))

colors <- c("seagreen2","royalblue","indianred")
colors.text <- rep(colors, each=5)

pch_1 <- 19
pch_3 <- 15
pch_5 <- 17
pch_9 <- 18

pch_all <- c(pch_3, pch_3, pch_3)

matplot(data, 
        #main="",
        #sub="",
        xlab="Rozdelenie do tém", ylab="Rýchlosť posielania producenta [msg/s]",
        xlim=c(1, 5), ylim=c(ymin, ymax),
        type="o", pch=pch_all, lty = 1, lwd = 1.3,
        col=colors,
        xaxt="n")
axis(1,at=c(1,2,3,4,5),labels=c("1-0-0 [1]", "2-0-1 [3]", "5-1-2 [8]", "10-2-4 [16]", "50-10-20 [80]"))
text(rep(c(1,2,3,4,5), 3), data.text, data.text, pos=3, col = colors.text, cex=0.7)
legend("topleft", inset=.02, title="Nastavenie producenta", c("ACKS=all","ACKS=1","Tranzakcie"), col=colors, horiz=FALSE, cex=0.8, lty = 1, lwd = 1.3)

