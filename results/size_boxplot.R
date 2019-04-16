data <- read.csv("kafka-latencies-boxplot.csv")

colors <- c("aquamarine","royalblue","indianred")
colors_dark <- c("aquamarine4","royalblue4","indianred4")
#Draw the boxplot, with the number of individuals per group
a <- boxplot(latencies~names,
        data=data,
        main="Oneskorenia správ medzi producentom a odberateľom.",
        xlab="Počet uzlov v klastri systému Kafka",
        ylab="Oneskorenie odberateľa [ms]",
        col=colors,
        border=colors_dark,
        varwidth=TRUE,
        pch=20,
        names=c("1", "1", "1", "3", "3", "3", "5", "5", "5", "9")
)

#text( c(1:nlevels(data$names)) , 150, paste(c("all", "one", "trans", "all", "one", "trans", "all", "one", "trans"),sep=""), col = "blue")
legend("topleft", inset=.02, title="Nastavenie Producenta", c("ACKS=all","ACKS=1","Tranzakcie"), fill=colors, horiz=TRUE, cex=0.8)
