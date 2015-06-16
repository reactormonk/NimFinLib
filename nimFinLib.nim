
##
## Program     : nimFinLib  
## 
## Status      : Development - alpha
## 
## License     : MIT opensource  
## 
## Version     : 0.1
## 
## Compiler    : nim 0.11.3
## 
## 
## Description : A basic library for financial calculations with Nim
## 
##               Yahoo historical stock data
##               
##               Yahoo current quotes
##               
##               Dataframe like structure for easy working with dataseries
##               
##               Returns calculations
##               
##               Ema calculation
##               
##               Date manipulations
##               
##               
##               Documents creation with nim doc nimFinLib ==> nimFinLib.html
##               
##               
##                            
##               
## Tested on   : Linux
##               
## ProjectStart: 2015-06-05
## 
## ToDo        : Ratios ,plotting, currency, metals
## 
##  
## Last        : 2015-06-16
## 
## Programming : qqTop
## 


import os,strutils,parseutils,sequtils,httpclient,strfmt,terminal,times,tables
import parsecsv,streams,algorithm,math,unicode

type
   
  Pf* {.inheritable.} = object 
      ## Pf type
      ## holds all portfolios similar to a master account
      ## portfolios are Nf objects
      pf* : seq[Nf]  ## pf holds all Nf type portfolios for an account
  
  
    
  Nf* {.inheritable.} = object of Pf 
      ## Nf type
      ## holds one portfolio with all relevant historic stocks data
      nx* : string   ## nx  holds portfolio name  e.g. MyGetRichPortfolio
      dx* : seq[Df]  ## dx  holds all stocks with historical data 
  
 
   
  Df* {.inheritable.} = object of Nf
    ## Df type
    ## holds individual stocks history data and RunningStat for close and adj.close
    ## even more items may be added like full company name etc in the future
    ## items are stock code, ohlcva, rc and rca . 
    stock* : string           ## yahoo style stock code 
    date*  : seq[string]
    open*  : seq[float]
    high*  : seq[float]
    low*   : seq[float]
    close* : seq[float]
    vol*   : seq[float]        ## volume
    adjc*  : seq[float]        ## adjusted close price
    rc*    : seq[Runningstat]  ## RunningStat for close price
    rca*   : seq[Runningstat]  ## RunningStat for adjusted close price
   
 
 
  Ts* {.inheritable.} = object
       ## Ts type
       ## is a simple timeseries object which can hold one 
       ## column of any OHLCVA data
       
       dd* : seq[string]  # date
       tx* : seq[float]   # data


template msgg*(code: stmt): stmt {.immediate.} =
      ## msgX templates 
      ## convenience templates for colored text output
      ## the assumption is that the terminal is white text and black background
      ## naming of the templates is like msg+color so msgy => yellow
      ## use like : msgg() do : echo "How nice, it's in green"
     
      setforegroundcolor(fgGreen)
      code
      setforegroundcolor(fgWhite)
      
template msgy*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgYellow)
      code
      setforegroundcolor(fgWhite)

template msgr*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgRed)
      code
      setforegroundcolor(fgWhite)

template msgc*(code: stmt): stmt {.immediate.} =
      setforegroundcolor(fgCyan)
      code
      setforegroundcolor(fgWhite)


template hdx*(code:stmt):stmt {.immediate.}  =
   echo ""
   echo repeat("+",tw)
   setforegroundcolor(fgCyan)
   code
   setforegroundcolor(fgWhite)
   echo repeat("+",tw)
   echo ""

  
proc timeseries*[T](self:T,ty:string): Ts =
     ## timeseries
     ## returns a Ts type date and one data column based on ty selection 
     ## input usually is a Df object and a string , if a string is in ohlcva
     ## the relevant series will be extracted from the Df object
     ## usage : timeseries(myDfObject,"o") , this would return 
     ##           dates in dd and open prices in ts
     var ts:Ts 
     ts.dd = self.date
     case ty 
     of "o": ts.tx = self.open
     of "h": ts.tx = self.high
     of "l": ts.tx = self.low
     of "c": ts.tx = self.close
     of "v": ts.tx = self.vol
     of "a": ts.tx = self.adjc
     return ts


proc showTimeseries* (ats:Ts,header,ty:string,N:int) {.discardable.} =
   ## showTimeseries 
   ## takes a Ts object as input as well as a header string
   ## for the data column , a string which can be one of
   ## head,tail,all and N for number of rows to display 
   ## usage : showTimeseries(myTimeseries,myHeader,"head|tail|all",rows)
   
   msgg() do : echo "{:<11} {:>11} ".fmt("Date",header) 
   if ty == "all":
      for x in 0.. <ats.tx.len:
          echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])  
   elif ty == "tail":
      for x in ats.tx.len-N.. <ats.tx.len:       
          echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])  
   elif ty == "head":
      for x in 0.. <N:
          echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])  
   else:
      ## head is the default in case an empty ty string was passed in
      for x in 0.. <N:
          echo "{:<11} {:>11} ".fmt(ats.dd[x],ats.tx[x])  
          

proc stock*(self: var Df) : string =
     ## Various convenience procs to access the data and some calcs like returns etc 
     ## stock,close,open,high,low,vol,adjc,date,rc,rca
     ## initDf,initPf,initNf 
     result = self.stock
     
proc close*(self: var Df) : seq[float] =
     result = self.close
     
proc open*(self: var Df) : seq[float] =
     result = self.open
     
proc high*(self: var Df) : seq[float] =
     result = self.high
     
proc low*(self: var Df) : seq[float] =
     result = self.low
     
proc vol*(self: var Df) : seq[float] =
     result = self.vol
     
proc adjc*(self: var Df) : seq[float] =
     result = self.adjc
     
proc date*(self: var Df) : seq[string] =
     result = self.date

proc rc*(self: var Df) : seq[RunningStat] =
     result = self.rc
     
proc rca*(self: var Df) : seq[RunningStat] =
     result = self.rca   


proc initPf*(apf:var PF):PF = 
     ## init a new empty account object
     apf.pf = @[]
     result = apf


proc initNf*(anf:var Nf):Nf =
    ## init a new empty portfolio object
    anf.nx = ""
    anf.dx = @[]
    result = anf 


proc initDf*(adf:var Df):Df =
    ## init stock data object 
    adf.stock = ""
    adf.date  = @[]
    adf.open  = @[]
    adf.high  = @[]
    adf.low   = @[]
    adf.close = @[]
    adf.vol   = @[]
    adf.adjc  = @[]
    adf.rc    = @[]
    adf.rca   = @[]
    result = adf



converter toTwInt(x: cushort): int = result = int(x)
when defined(Linux):
    proc getTerminalWidth*() : int =
      ## getTerminalWidth
      ## 
      ## utility to easily draw correctly sized lines on linux terminals
      ## 
      ## and get linux get terminal width
      ## 
      ## for windows this currently is set to terminalwidth 80 
      ## 
      type WinSize = object
        row, col, xpixel, ypixel: cushort
      const TIOCGWINSZ = 0x5413
      proc ioctl(fd: cint, request: culong, argp: pointer)
        {.importc, header: "<sys/ioctl.h>".}
      var size: WinSize
      ioctl(0, TIOCGWINSZ, addr size)
      result = toTwInt(size.col)
      
    var tw* = getTerminalWidth()
    var aline* = repeat("-",tw)

# will change this once windows gets a real terminal or shell

when defined(Windows):
   tw = repeat("-",80)



proc currentStocks(aurl:string) {.discardable.} =
  ## currentStocks 
  ## 
  ## display routine for current stock quote maybe 15 mins delayed
  ## 
  ## not callable
  ## 
  for line in getContent(aurl).splitLines:
      var data = line[1..line.high].split(",")
      if data.len > 0:
              setforegroundcolor(fgGreen)
              echo "Code : {:<10} Name : {}  Market : {}".fmt(data[0],data[1],data[2])
              setforegroundcolor(fgWhite)
              echo "Date : {:<12}{:<9}    Price  : {:<8} Volume : {:>12}".fmt(data[4],data[5],data[3],data[8])
              echo "Open : {:<8} High : {:<8} Change : {} Range : {}".fmt(data[6],data[7],data[9],data[10])                
              echo repeat("-",tw)


proc currentIndexes(aurl:string) {.discardable.} =
  ## currentIndexes
  ## 
  ## display routine for current index quote
  ## 
  ## not callable
  ## 
  for line in getContent(aurl).splitLines:
      var data = line[1..line.high].split(",")
      if data.len > 0:
              setforegroundcolor(fgYellow)
              echo "Code : {:<10} Name : {}  Market : {}".fmt(data[0],data[1],data[2])
              setforegroundcolor(fgWhite)
              echo "Date : {:<12}{:<9}    Index  : {:<8}".fmt(data[4],data[5],data[3])
              echo "Open : {:<8} High : {:<8} Change : {} Range : {}".fmt(data[6],data[7],data[9],data[10])                
              echo repeat("-",tw)


proc showCurrentIndexes*(idxs:string){.discardable.} =
   ## showCurrentIndexes
   ## 
   ## callable display routine for currentIndexes
   ## 
   hdx(echo "Index Data")
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % idxs
   currentIndexes(qurl)  


proc showCurrentStocks*(stcks:string){.discardable.} =
   ## showCurrentStocks
   ## 
   ## callable display routine for currentStocks
   ## 
   hdx(echo "Stocks Current Quote")
   var qurl="http://finance.yahoo.com/d/quotes.csv?s=$1&f=snxl1d1t1ohvcm" % stcks
   currentStocks(qurl)  



proc day*(aDate:string) : string = 
   ## Various procs for massaging the startdate and enddate into a format for
   ## 
   ## currently used yahoo url to fetch history data
   ## 
   ## Format dd
   ## 
   aDate.split("-")[2]


proc month*(aDate:string) : string =
  ## month starts with 00 for jan
  ## 
  ## Format MM
  # 
  var asdm = $(parseInt(aDate.split("-")[1])-1)
  if len(asdm) < 2: asdm = "0" & asdm
  result = asdm
    
proc year*(aDate:string) : string = aDate.split("-")[0]
     ## Format yyyy


proc intervalsecs*(startDate,endDate:string) : float =
      ## interval procs returns time elapsed between two dates in secs,hours etc. 
      ## 
      var f     = "yyyy-MM-dd"
      var ssecs = toSeconds(timeinfototime(startDate.parse(f)))
      var esecs = toSeconds(timeinfototime(endDate.parse(f)))
      var isecs = esecs - ssecs  
      result = isecs
 
proc intervalmins*(startDate,endDate:string) : float =
      var imins = intervalsecs(startDate,endDate) / 60
      result = imins
 
proc intervalhours*(startDate,endDate:string) : float =
      var ihours = intervalsecs(startDate,endDate) / 3600
      result = ihours
 
proc intervaldays*(startDate,endDate:string) : float =
      var idays = intervalsecs(startDate,endDate) / 3600 / 24
      result = idays
   
proc intervalweeks*(startDate,endDate:string) : float =
      var iweeks = intervalsecs(startDate,endDate) / 3600 / 24 / 7
      result = iweeks
     
proc intervalmonths*(startDate,endDate:string) : float =
      var imonths = intervalsecs(startDate,endDate) / 3600 / 24 / 365  * 12
      result = imonths 
      
proc intervalyears*(startDate,endDate:string) : float =
      var iyears = intervalsecs(startDate,endDate) / 3600 / 24 / 365
      result = iyears
 
proc getSymbol2*(symb,startDate,endDate : string) : Df =
    ## getSymbol2
    ## 
    ## the work horse proc for getting yahoo data in csv format 
    ## 
    ## and then to parse into a Df object
    ## 
    # feedbackline can be commented out if not desired 
    # 
    stdout.write("{:<15}".fmt("Processing   : "))
    msgg() do: stdout.write("{:<8} ".fmt(symb))
    stdout.write("{:<11} {:<11}".fmt(startDate,endDate))
    # end feedback line
    
    # set up dates
    var sdy = year(startDate)
    var sdm = month(startDate)
    var sdd = day(startDate)
          
    var edy = year(endDate)
    var edm = month(endDate)
    var edd = day(endDate)

    # set up df variables    
    var datx = ""
    var datdf = newSeq[string]()
    var opex = 0.0  
    var opedf = newSeq[float]()
    var higx = 0.0
    var higdf = newSeq[float]()
    var lowx = 0.0
    var lowdf = newSeq[float]()
    var closx = 0.0
    var closdf = newSeq[float]()
    var volx = 0.0
    var voldf = newSeq[float]()
    var adjclosx = 0.0
    var adjclosdf = newSeq[float]()  
        
    # add RunningStat capability for close and adjusted close prices
    var closeRC  : Runningstat
    var closeRCA : Runningstat
          
    # note to dates for this yahoo url according to latest research
    # a=04  means may  a=00 means jan start month
    # b = start day 
    # c = start year
    # d = end month  05 means jun 
    # e = end day 
    # f = end year
    # we use the csv string , yahoo json format only returns limited data 1.5 years or less
    var qurl = "http://real-chart.finance.yahoo.com/table.csv?s=$1&a=$2&b=$3&c=$4&d=$5&e=$6&f=$7&g=d&ignore=.csv" % [symb,sdm,sdd,sdy,edm,edd,edy]
    var headerset = [symb,"Date","Open","High","Low","Close","Volume","Adj Close"]
    var c = 0
    var hflag  : bool # used for testing maybe removed later
    var astock : Df   # this will hold our result history data for one stock
                    
    # naming outputfile nimfintmp.csv as many stock symbols have dots like 0001.HK
    # could also be done to be in memory like /shm/  this file will be auto removed.
    
    var acvsfile = "nimfintmp.csv"
    downloadFile(qurl,acvsfile)
    var s = newFileStream(acvsfile, fmRead)
    if s == nil:
       # in case of problems with the yahoo csv file we show a message
       msgr() do : echo "Hello : Data file for $1 could not be opened " % symb

    # now parse the csv file
    var x: CsvParser
    open(x, s , acvsfile, separator=',')
    while readRow(x):
      # a way to get the actual csv header , but here we use our custom headerset with more info
      # if validIdentifier(x.row[0]):
      #  header = x.row
      c = 0 # counter to assign item to correct var
      for val in items(x.row):
        if val in headerset:
              hflag = true
            
        else:   
              c += 1
              hflag = false
              
              case c 
              of 1:
                    datx = val
                    datdf.add(datx)
                
              of 2:
                    opex = parseFloat(val) 
                    opedf.add(opex)
                  
              of 3:
                    higx = parseFloat(val)
                    higdf.add(higx)
                  
              of 4:
                    lowx = parseFloat(val)
                    lowdf.add(lowx)
                  
              of 5:
                    closx = parseFloat(val)
                    closeRC.push(closx)     ## RunningStat for close price
                    closdf.add(closx)
                  
              of 6:
                    volx = parseFloat(val)     
                    voldf.add(volx)
                  
              of 7:
                    adjclosx = parseFloat(val)    
                    closeRCA.push(adjclosx)  ## RunningStat for adj close price
                    adjclosdf.add(adjclosx)
              
              else :
                    msgr() do : echo "Csv Data in unexpected format for Stock :",symb

    # feedbacklines can be commented out  
    msgc() do:
              stdout.writeln(" --> Rows processed : ",processedRows(x))
              
              
    # close CsvParser
    close(x)
    
    # put the collected data into Df type
    astock.stock = symb
    astock.date  = datdf
    astock.open  = opedf
    astock.high  = higdf
    astock.low   = lowdf
    astock.close = closdf
    astock.adjc  = adjclosdf
    astock.vol   = voldf
    astock.rc    = @[]
    astock.rca   = @[]
    astock.rc.add(closeRC)
    astock.rca.add(closeRCA)
      
    # clean up
    removeFile(acvsfile)
    # send astock back
    result = astock
      
    
proc last*[T](self : seq[T]): T =
          ## Various data navigation routines
          ## 
          ## first,last,head,tail 
          ## 
          ## last means most recent row 
          ## 
          result = self[self.low]
          
    
proc first*[T](self : seq[T]): T =
          ## first means oldest row 
          ## 
          result = self[self.high]
  
proc tail*[T](self : seq[T] , n: int) : seq[T] =
          ## tail means most recent rows 
          ## 
          if len(self) >= n:
             result = self[0.. <n]
          else:
             result = self[0.. <len(self)]
 
proc head*[T](self : seq[T] , n: int) : seq[T] =
          ## head means oldest rows 
          ## 
          var self2 = reversed(self)
          if len(self2) >= n:
             result = self2[0.. <n].tail(n)
          else:
             result = self2[0.. <len(self2)].tail(n)    
 
 
proc lagger*[T](self:T , days : int) : T =
     ## lagger
     ## 
     ## often we need a timeseries off by x days
     ## 
     ## this functions provides this
     ## 
     var lgx = self[days.. <self.len]
     result = lgx

 
proc dailyReturns*(self:seq[float]):seq = 
      ## dailyReturns
      ## 
      ## daily returns calculation gives same results as dailyReturns in R / quantmod
      ## 
      var k = 1
      var lgx = newSeq[float]()
      for z in 1+k.. <self.len:
          lgx.add(1-(self[z] / self[z-k]))  
      result = lgx   
                         

proc showdailyReturnsCl*(self:Df , N:int) {.discardable.} =
      ## showdailyReturnsCl
      ## 
      ## display returns based on close price
      ## 
      ## formated output to show date and returns columns
      ## 
      var dfr = self.close.dailyReturns    # note the first in seq corresponds to date closest to now
      # we also need to lag the dates  
      var dfd = self.date.lagger(1) 
      # now show it with symbol , date and close columns
      echo ""
      msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Returns")
      # show limited rows output if c<>0
      if N == 0:
        for  x in 0.. <dfr.len:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
      else:
        for  x in 0.. <N:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
  

proc showdailyReturnsAdCl*(self:Df , N:int) {.discardable.} =
      ## showdailyReturnsAdCl 
      ## 
      ## returns based on adjusted close price
      ## 
      ## formated output to only show date and returns
      ## 
      var dfr = self.adjc.dailyReturns    # note the first in seq corresponds to date closest to now
      # we also need to lag the dates 
      var dfd = self.date.lagger(1) 
      # now show it with symbol , date and close columns
      echo ""
      msgg() do: echo "{:<8} {:<11} {:>15}".fmt("Code","Date","Returns")
      # show limited output if c<>0
      if N == 0:
        for  x in 0.. <dfr.len:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])
      else:
        for  x in 0.. <N:
             echo "{:<8} {:<11} {:>15.10f}".fmt(self.stock,dfd[x],dfr[x])  
  
  
proc sumdailyReturnsCl*(self:Df) : float =
      ## sumdailyReturnsCl
      ## 
      ## returns sum based on close price
      ## 
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but 
      # the sum is of by too much , maybe it is in the missing values
      var dR = self.close.dailyReturns
      var sumdfr = sum(dR)
      # feedback line can be commented out
      msgy() do: echo "Returns on Close Price calculated : ", dR.len
      result = sumdfr 

  
proc sumdailyReturnsAdCl*(self:Df) : float =
      ## sumdailyReturnsAdCl
      ## 
      ## returns sum based on adjc 
      ## 
      # returns a sum of dailyreturns but is off from quantmod more than expected why ?
      # the len of seq roughly the same of by 1-2 vals as expected but 
      # the sum is of by too much , maybe it is in the missing values
      var dR = self.adjc.dailyReturns
      var sumdfr = sum(dR)
      # feedback line can be commented out
      msgy() do: echo "Returns on Close Price calculated : ", dR.len
      result = sumdfr 


proc statistics*(x:Runningstat) {.discardable.} =
        ## statistics
        ## 
        ## display output of a runningstat object
        ## 
        echo "RunningStat Sum     : ", $formatFloat(x.sum,ffDecimal,5)
        echo "RunningStat Var     : ", $formatFloat(x.variance,ffDecimal,5)
        echo "RunningStat mean    : ", $formatFloat(x.mean,ffDecimal,5)
        echo "RunningStat Std     : ", $formatFloat(x.standardDeviation,ffDecimal,5)
        echo "RunningStat Min     : ", $formatFloat(x.min,ffDecimal,5)
        echo "RunningStat Max     : ", $formatFloat(x.max,ffDecimal,5)
        
        
proc stockDf*(dx : Df) : string =
  ## stockDf
  ## 
  ## get the stock name from a Df object and return as string
  ## 
  var stk: string = dx.stock
  result = stk        
  


# emaflag = false meaning all ok
# if true some problem to indicate to following calcs not to proceed

var emaflag : bool = false 

proc CalculateEMA(todaysPrice : float , numberOfDays: int , EMAYesterday : float) : float =
   ## supporting proc for ema calculation, not callable
   ## 
   var k = 2 / (float(numberOfDays) + 1.0)
   var ce = (todaysPrice * k) + (EMAYesterday * (1.0 - k))
   result = ce

proc ema* (dx : Df , N: int) : Ts =
    ## ema
    ## 
    ## exponential moving average
    ## 
    ## returns a Ts object loaded with date,ema pairs
    ## 
    ## calling with Df object and number of days for moving average
    ## 
    ## results match R quantmod/TTR
    ## 
    
    ## we need at least 5 * N > 100 days of data or ema will be skewed or invalid
    ## 
    ## EMA = Price(t) * k + EMA(y) * (1 – k)
    ## 
    # t = today, y = yesterday, N = number of days in EMA, k = 2/(N+1)
    
    var m_emaSeries : Ts # we use our Ts object to hold a series of dates and ema
    m_emaSeries.dd = @[]
    m_emaSeries.tx = @[]
    if dx.close.len < ( 5 * N):
       emaflag = true
       msgr() do : echo "Insufficient data for valid ema calculation, need min. $1 data points" % $(5 * N)
      
    else:
      # so to calc this we need our price series dx.close 
      # which holds all available historical prices
      # 1) Start by calculating k for the given timeframe. 2 / (22 + 1) = 0,0869
      
      # lets calc the first ema by hand as per 
      # http://www.iexplain.org/ema-how-to-calculate/
      # note that our list is upside down so the first is actually the bottom in our list
      # compared to quantmod ema,22 we are still off a bit so this needs further adjustment
      # 
      var nk = 2/(N + 1)
      var ns = 0.0
      for x in countdown(dx.close.len-1,dx.close.len-N,1):  # we count down coz first in is at bottom
          ns = ns + dx.close[x]
          
      ns = ns / float(N)
      ns = ns * (1 - nk)
      # now we need the next the closing
      var ms = dx.close[dx.close.len - (N + 1)]
      ms = ms * nk
      var yesterdayEMA = ms + ns   # at this stage we have a first ema which will be used for yday
              
      for x in countdown(dx.close.len-1,0,1):  # ok but we get the result in reverse
          # call the EMA calculation
          var aema = CalculateEMA(dx.close[x], N, yesterdayEMA)
          # put the calculated ema in an table
          m_emaSeries.dd.add(dx.date[x])
          m_emaSeries.tx.add(aema)
          # make sure yesterdayEMA gets filled with the EMA we used this time around
          yesterdayEMA = aema
      
      
    result = m_emaSeries


proc showEma* (emx:Ts , N:int) {.discardable.} =
   ## showEma
   ## 
   ## convenience proc to display ema series with dates
   ## 
   ## input is a ema series Ts object and rows to display
   ## 
   ## latest data is on top
   ## 
   echo()
   msgg() do : echo "{:<11} {:>11} ".fmt("Date","EMA") 
   for x in countdown(emx.dd.len-1,emx.dd.len-N,1) : 
          echo "{:<11} {:>11} ".fmt(emx.dd[x],emx.tx[x])
     

# --------------------------------------------------------------------------------------------
# Development snippets to ready for use yet
# --------------------------------------------------------------------------------------------
#
# ToDo or not ok yet
# proc sharpe ()
# 
# proc sharpeannualized ()
# 
# proc sortino ()
# 
# proc drawdown()

# Formulars ex R PortfolioAnalytics MAR risk factor
# proc downsidedeviation(R, MAR) = sqrt(1/n * sum(t=1..n)((min(R(t)-MAR, 0))^2))
# 
# proc downsidevariance(R, MAR) = 1/n * sum(t=1..n)((min(R(t)-MAR, 0))^2)
# 
# proc downsidepotential(self:Df): float = 

proc rsi* (dx:Df , N: int):Ts = 
  ## rsi
  ## 
  ## oscillator
  ## 
  ## under Development
  ## 
  ## This is not ok yet , values seem incorrect 
  
  # values are off from quantmod rsi 
  
  # call : rsi(dfobject, numberofdays for ema)
  
  # that means we need to calc ema 2 times so we make to series of our closeprices
  var closeup : Df
  var closedn : Df
  
  closeup.date  = @[]
  closeup.close = @[]
  closedn.date  = @[]
  closedn.close = @[]
  
  for x in 1.. <dx.close.len:
      if dx.close[x] >= dx.close[x-1]:
         
         closeup.date.add(dx.date[x])
         closeup.close.add(dx.close[x])
         closedn.date.add(dx.date[x])
         closedn.close.add(0.0)
         
         
      else :
         closeup.date.add(dx.date[x-1])
         closeup.close.add(0)
         closedn.date.add(dx.date[x-1])
         closedn.close.add(dx.close[x-1])
         
  var emaup = ema(closeup,N)
  var emadn = ema(closedn,N)
  var maxl = 0
  # maxl holds len of the shorter series to avoid index errors
  maxl = min(emaup.dd.len,emadn.dd.len)
   
  var arsi : Ts
  arsi.dd = @[]
  arsi.tx = @[]
  for x in 0.. <maxl:
     var rsi = 100 * (emaup.tx[x] / (emaup.tx[x] + emadn.tx[x]))
     arsi.dd.add(emaup.dd[x])
     arsi.tx.add(rsi)
  # we return a Ts object holding date and rsi columns
  result = arsi    
      


proc showRsi* (rsx:Ts , N:int) {.discardable.} = 
    ## showRsi 
    ## 
    ## a convenience proc to display rsi latest is on top
    ## 
    echo ()
    msgg() do : echo "{:<11} {:>11}".fmt("Date","RSI")
    for x in countdown(rsx.dd.len-1,rsx.dd.len-N,1) :
         echo "{:<11.f4} {:>11.f4} ".fmt(rsx.dd[x],rsx.tx[x])

                    

proc sharpe*(adfstock:Df, adfriskfree:Df):float = 
  ## sharpe ratios based on std.dev
  ## it does not match with R / quantmod output 
  ## 
  ## under Development
  ## 
  ## This is not ok yet 
  
  #  values seem incorrect  this ratios seem to be calculated nilly willy differently everywhere
  # maybe becoz they have a 95% p value factored in
  # also note we use riskfree as 0  so adfriskfree is
  # currently not really required 
  # 
  # ingredients (returnsstock - returnsriskfree) / stdev stock
  var retstock = dailyReturns(adfstock.close)
  var retrf    = dailyReturns(adfriskfree.close)

  var tailrows = min(retstock.len,retrf.len)
  var sumrs = sumdailyReturnsCl(adfstock)  #.close.tail(tailrows))
  var sumrr = sumdailyReturnsCl(adfriskfree) #.close.tail(tailrows))

  var stdev    = adfstock.rc[0].standardDeviation
  var stdevrf  = adfriskfree.rc[0].standardDeviation
  # pseudo below as we deduct seq from seq
  # note formular in quantmod is 
  # \frac{\overline{(R_{a}-R_{f})}}{√{σ_{(R_{a}-R_{f})}}}
  # frac(retstock - retrf) / sqrt(stdev(retstock - retrf))
  # the question is how it is calculated internaly
  # so best for us here to assume the riskfree thing = 0
  # hmm but we are still a bit off from quantmod
  # 
  var sharpx   = (sumrs - 0) / sqrt(stdev - 0)
  # testing
  #   msgy() do :
  #              echo "Sumrs  : ",sumrs
  #              echo "Sumrr  : ",sumrr
  #              echo "stdev  : ",stdev
  #              echo "stdevrf: ",stdevrf
  # end testing
  
  result = sharpx



 
# proc bollinger

# proc overbought/oversold


# procs for future use
 
proc logisticf* (z:float):float =
     ## logisticf
     ## 
     ## maps the input z to an output between 0 and 1 
     ## 
     # good for smaller numbers -10 .. 10
     var lf:float = 1 / (1 + pow(E,-z))
     result = lf

proc logisticf_derivative* (z:float): float =  
     ## logisticf_derivative
     ## 
     ## returns derivative of logisticf for gradient solutions
     ## 
     result = logisticf(z) * (1 - logisticf(z))

#------------------------------------------------------------------------------------------