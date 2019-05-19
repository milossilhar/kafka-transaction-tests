#!/usr/bin/env python3

import os

path = "."

diffValues = 5

def prod_to_index(prod):
    if (prod == "1"):
        return 0
    if (prod == "2"):
        return 1
    if (prod == "5"):
        return 2
    if (prod == "10"):
        return 3
    if (prod == "50"):
        return 4

resultDict={}

files = os.listdir(path)
files.sort()
for name in files:
    if not name.endswith(".out"):
        continue
    name_replaced = name.replace("_", "-")
    name_splitted = name_replaced.split("-")
    if name_splitted[1] == "producer" and name_splitted[2] == "trans":
        print(name)
        producer_file = open(name, "r")
        for line in producer_file:
            if line.startswith("MPS - "):
                category = "con-" + name_splitted[0] + "-" + name_splitted[2]
                if not category in resultDict:
                    resultDict[category]=[None]*diffValues
                newLine = line.replace("\n", "")
                resultDict[category][prod_to_index(name_splitted[4])] = newLine.replace("MPS - ", "")

CSV_FILE = "producer_plot_cluster.csv"

header = ",".join(resultDict.keys()) + "\n"
maxRuns = max(list(map(len, resultDict.values())))
for key, listValue in resultDict.items():
    if len(listValue) < maxRuns:
        diff = maxRuns - len(listValue)
        resultDict[key] = listValue + [0 * i for i in range(diff)]

resultFile = ""
for i in range(maxRuns):
    resultFile += ",".join(list(map(lambda x: str(x[i]), resultDict.values()))) + "\n"

with open(CSV_FILE, "w") as csvfile:
    csvfile.write(header)
    csvfile.write(resultFile)

