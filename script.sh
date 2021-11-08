#!/usr/bin/env bash
# crontab command. change ""/home/tauqeer/assig5/script.sh" with path of script
# { echo "* * * * * /home/tauqeer/assig5/script.sh"; } | crontab - && crontab -l

#max_mem = max(max(file1) , max(file2) , max (file3)) | if pid are not same and mem is same we log multiple entries.

#Get total RAM or Memory of the device
while IFS=":" read -r a b
do
  case "$a" in
   MemTotal*) phymem="$b"
  esac
done <"/proc/meminfo"
Totalmemory=0
i=0
for word in $phymem; do
  if [[ $i == 0 ]]; then
    Totalmemory=$word
  fi
  ((i++))
done

#Calculate memory in Mb form percentage and Totalmemory
calculatemem(){
  x=`echo "(($1*$2)/100)/1024" | bc`
  echo $x
}

basedir="/home/tauqeer/assig5"
file1="$basedir/file1.txt"
file2="$basedir/file2.txt"
file3="$basedir/file3.txt"
file4="$basedir/memory_log.txt"

#create files.
touch "$file1" "$file2" "$file3"

#Get last line of file to check if it is Most Recently used MRU
flag1=$( tail -n 1 "$file1" )
flag2=$( tail -n 1 "$file2" )
flag3=$( tail -n 1 "$file3" )
MRU="MRU"

file=$file1
if [[ -e "$file4" ]]; then
  flag4=$( tail -n 1 "$file4" )
  # echo "$flag4"
fi

#find Most recently used file
if [[ "$flag1" == "$MRU" ]]; then
  sed -i "$ d" "$file1"
  file="$file2"
elif [[ "$flag2" == "$MRU" ]]; then
  sed -i "$ d" "$file2"
  file="$file3"
elif [[ "$flag3" == $MRU ]]; then
  if [[ ! -e $file4 ]]; then
    touch "$file4"
    echo "Timestamp           PName   PID      mem-c(3min)  mem-c(mb)(3min)">>$file4
  fi
  sed -i "$ d" "$file3"
  file="$file4"
elif [[ "$flag4" == "$MRU" ]]; then
    sed -i "$ d" "$file4"
    file="$file1"
fi

#This function writes 5 most memory consuming process to file.
writeprocess(){

echo -n >"$file"
output=$(ps aux --sort rss | tail -5)
while read -r line; do
  echo "$line">>"$file"
done <<<"$output"

declare -a array=()
j=1
while IFS= read -r line; do
  array[j]=$line
  ((j++))
done<"$file"

index="USER    PID  CPU MEM VSZ     RSS  TTY STAT STRT TIME APP"
echo "$index">"$file"
for line in "${array[@]}";do
  i=0
  # echo "$line"
  for word in $line; do
    if [[ "$i" -lt 10 ]]; then
      echo -n "$word ">>"$file"
      ((i++))
    elif [[ "$i" -eq 10 ]]; then
      echo "${word##*/}">>"$file"
      ((i++))
    fi
done
done

echo "MRU">>"$file"
}

#This function finds out the highest memory consuming process in 3 min and logs it.
memanalysis(){
  data1=$( tail -n 1 "$file1" )
  data2=$( tail -n 1 "$file2" )
  data3=$( tail -n 1 "$file3" )
  pid1=0;pid2=0;pid3=0
  pname1='0';pname2='0';pname3='0'
  mem1=0;mem2=0;mem3=0
  i=1
  for word in $data1; do
    if [[ $i == 2  ]]; then
      pid1=$word
    elif [[ $i == 4 ]]; then
      mem1=$word
    elif [[ $i == 11 ]]; then
      pname1=$word
    fi
    ((i++))
  done
  i=1
  for word in $data2; do
    if [[ $i == 2  ]]; then
      pid2=$word
    elif [[ $i == 4 ]]; then
      mem2=$word
    elif [[ $i == 11 ]]; then
      pname2=$word
    fi
    ((i++))
  done
  i=1
  for word in $data3; do
    if [[ $i == 2  ]]; then
      pid3=$word
    elif [[ $i == 4 ]]; then
      mem3=$word
    elif [[ $i == 11 ]]; then
      pname3=$word
    fi
    ((i++))
  done
  #calculat  memory in MB
  mem1_mb=`calculatemem "$mem1" "$Totalmemory"`
  mem2_mb=`calculatemem "$mem2" "$Totalmemory"`
  mem3_mb=`calculatemem "$mem3" "$Totalmemory"`

  data1="`date +%Y-%m-%d_%H-%M-%S` ${pname1} ${pid1}        ${mem1}%       ${mem1_mb}"
  data2="`date +%Y-%m-%d_%H-%M-%S` ${pname2} ${pid2}        ${mem2}%       ${mem2_mb}"
  data3="`date +%Y-%m-%d_%H-%M-%S` ${pname3} ${pid3}        ${mem3}%       ${mem3_mb}"
  # echo $mem1 $mem2 $mem3 $pid1 $pid2 $pid3
  if [[ $(bc -l <<<"${mem1}>${mem2}") -eq 1 && $(bc -l <<<"${mem1}>${mem3}") -eq 1 ]]; then
    flag=1
    # echo $flag
  elif [[ $(bc -l <<<"${mem2}>${mem1}") -eq 1  && $(bc -l <<<"${mem2}>${mem3}") -eq 1 ]]; then
    flag=2
    # echo $flag
  elif [[ $(bc -l <<<"${mem3}>${mem1}") -eq 1 && $(bc -l <<<"${mem3}>${mem2}") -eq 1 ]]; then
    flag=3
    # echo $flag
  elif [[ $(bc -l <<<"${mem1}==${mem2}") -eq 1 && $(bc -l <<<"${mem1}>${mem3}") -eq 1 ]]; then
    flag=4
    # echo $flag
  elif [[ $(bc -l <<<"${mem1}==${mem3}") -eq 1 && $(bc -l <<<"${mem1}>${mem2}") -eq 1 ]]; then
    flag=5
    # echo $flag
  elif [[ $(bc -l <<<"${mem2}==${mem3}") -eq 1 && $(bc -l <<<"${mem3}>${mem1}") -eq 1 ]]; then
    flag=6
    # echo $flag
  elif [[ $(bc -l <<<"${mem1}==${mem2}") -eq 1 && $(bc -l <<<"${mem1}==${mem3}") -eq 1 ]]; then
    flag=7
    # echo $flag
  fi

  if [[ $flag == 1 ]]; then
    echo "$data1">>"$file4"
  fi

  if [[ $flag == 2 ]]; then
    echo "$data2">>"$file4"
  fi
  if [[ $flag == 3 ]]; then
    echo "$data3">>"$file4"
  fi
  if [[ $flag == 4 ]]; then
    if [[ $(bc -l <<<"${pid1}==${pid2}") -eq 1 ]]; then
      echo "$data1">>"$file4"
    else
      echo "$data1">>"$file4"
      echo "$data2">>"$file4"
    fi
  fi

  if [[ $flag == 5 ]]; then
    if [[ $(bc -l <<<"${pid1}==${pid3}") -eq 1 ]]; then
      echo "$data1">>"$file4"
    else
      echo "$data1">>"$file4"
      echo "$data3">>"$file4"
    fi
  fi

  if [[ $flag == 6 ]]; then
    if [[ $(bc -l <<<"${pid2}==${pid3}") -eq 1 ]]; then
      echo "$data2">>"$file4"
    else
      echo "$data2">>"$file4"
      echo "$data3">>"$file4"
    fi
  fi

  if [[ $flag == 7 ]]; then
    if [[ $(bc -l <<<"${pid1}==${pid2}") -eq 1 && $(bc -l <<<"${pid1}==${pid3}") -eq 1 ]]; then
      echo "$data1">>"$file4"
    elif [[ $(bc -l <<<"${pid1}==${pid2}") -eq 1 && $(bc -l <<<"${pid1}!=${pid3}") -eq 1 ]]; then
      echo "$data1">>"$file4"
      echo "$data3">>"$file4"
    elif [[ $(bc -l <<<"${pid1}==${pid3}") -eq 1 && $(bc -l <<<"${pid1}!=${pid2}") -eq 1 ]]; then
      echo "$data1">>"$file4"
      echo "$data2">>"$file4"
    elif [[ $(bc -l <<<"${pid2}==${pid3}") -eq 1 && $(bc -l <<<"${pid1}!=${pid2}") -eq 1 ]]; then
      echo "$data1">>"$file4"
      echo "$data2">>"$file4"
    elif [[ $(bc -l <<<"${pid1}!=${pid2}") -eq 1 && $(bc -l <<<"${pid2}!=${pid3}") -eq 1 ]]; then
      echo "$data1">>"$file4"
      echo "$data2">>"$file4"
      echo "$data3">>"$file4"
    fi
    fi
    echo "MRU">>$file4
}


#Driver code
if [[ "$file" == "$file1" || "$file" == "$file2" || "$file" == "$file3" ]]; then
  writeprocess
fi

if [[ "$file" == "$file4" ]]; then
  memanalysis
  sed -i "$ d" "$file4"
  file="$file1"
  writeprocess
fi
