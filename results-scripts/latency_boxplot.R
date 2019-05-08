data <- read.csv("latency_boxplot.csv")

data.aggregated <- aggregate(data$latencies, by=list(Config=data$names), FUN=mean)

data.text.values <- round(unlist(data.aggregated$x), 2)
data.text <- format(data.text.values, decimal.mark = ",")

colors <- c("seagreen2","royalblue","indianred")
colors_dark <- c("seagreen4","royalblue4","indianred4")
#Draw the boxplot, with the number of individuals per group
a <- boxplot(latencies~names,
        data=data,
        #main="Oneskorenia správ medzi producentom a odberateľom.",
        xlab="Počet uzlov v klastri systému Kafka",
        ylab="Oneskorenie odberateľa [ms]",
        log="y",
        col=colors,
        width=rep(0.5,12),
        border=colors_dark,
        pch=20,
        names=c(rep("1", 3), rep("3", 3), rep("5", 3), rep("9", 3))
)

text( c(1:nlevels(data$names)) , 1, data.text, col = colors_dark, cex=0.8)
legend("topleft", inset=.02, title="Nastavenie Producenta", c("ACKS=all","ACKS=1","Tranzakcie"), fill=colors, horiz=TRUE, cex=0.8)

