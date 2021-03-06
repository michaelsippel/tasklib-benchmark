#!/bin/sh

mkdir build
cd build
cmake ..
make -j
cd ..

n_repeat=5

for lib in redgrapes superglue quark;
do
    truncate -s 0 ${lib}_data

    for n_tasks in 1 2 4 8 16 32 64 128 256 512 1024 2048
    do
	
	DATA=""

#	for i in $(seq $n_repeat);
#	do
	    echo $lib $n_tasks
	    OUTPUT=$(numactl -C 0-1 ./build/$lib $n_tasks)

	    SCHEDUL_TIME=$(echo $OUTPUT | grep -Po 'deadtime: \K[0-9.]*')
	    EMPLACE_TIME=$(echo $OUTPUT | grep -Po 'emplace time: \K[0-9.]*')

#	    DATA="$DIFF $EMPLACE_TIME"
#	done

#	echo $DATA
#	MIN=$(awk '{min = $1; for(i=1;i<=NF;i++) { if($i < min) { min = $i } } } END { printf "%f\n", min }' <<< $DATA)
#	MAX=$(awk '{max = $1; for(i=1;i<=NF;i++) { if($i > max) { max = $i } } } END { printf "%f\n", max }' <<< $DATA)
#	AVG=$(awk '{sum = 0; for(i=1;i<=NF;i++) { sum += $i } } END { printf "%f\n", sum/NF }' <<< $DATA)

	#	echo "min=$MIN, max=$MAX, avg=$AVG"
	echo "$n_tasks $EMPLACE_TIME $SCHEDUL_TIME" >> ${lib}_data
    done

done

EMPLACE_OUT="bench_emplace_overhead.png"
SCHEDULE_OUT="bench_schedule_overhead.png"

gnuplot -p \
   -e "set output \"$EMPLACE_OUT\"" \
   -e 'set terminal pngcairo enhanced truecolor size 1200,900 font "DejaVu Sans,24"' \
   -e "set title \"Task-Creation Overhead\"" \
   -e 'set xlabel "number of tasks"' \
   -e 'set ylabel "task creation overhead (μs)"' \
   -e 'set key right top' \
   -e 'set grid' \
   -e 'set logscale x 2' \
   -e 'set logscale y 2' \
   -e 'set style line 11 lc rgb "#555555" lt 1' \
   -e 'set border 3 back ls 11' \
   -e 'set tics nomirror' \
   -e 'set style line 12 lc rgb "#555555" lt 0 lw 1' \
   -e 'set grid back ls 12'  \
   -e 'plot "quark_data" using 1:2 title "Quark" with linespoints lt 5 dt 3 lc rgb "#006DD5",
            "superglue_data" using 1:2 title "SuperGlue" with linespoints lt 7 dt 4 lc rgb "#20D500",
            "redgrapes_data" using 1:2 title "RedGrapes" with linespoints lt 9 dt 7 lc rgb "#670496"'

gnuplot -p \
   -e "set output \"$SCHEDULE_OUT\"" \
   -e 'set terminal pngcairo enhanced truecolor size 1200,900 font "DejaVu Sans,24"' \
   -e "set title \"Scheduling Overhead\"" \
   -e 'set xlabel "number of tasks"' \
   -e 'set ylabel "scheduling overhead per task (μs)"' \
   -e 'set key right top' \
   -e 'set grid' \
   -e 'set logscale x 2' \
   -e 'set logscale y 2' \
   -e 'set style line 11 lc rgb "#555555" lt 1' \
   -e 'set border 3 back ls 11' \
   -e 'set tics nomirror' \
   -e 'set style line 12 lc rgb "#555555" lt 0 lw 1' \
   -e 'set grid back ls 12'  \
   -e 'plot "quark_data" using 1:3 title "Quark" with linespoints lt 5 dt 3 lc rgb "#006DD5",
            "superglue_data" using 1:3 title "SuperGlue" with linespoints lt 7 dt 4 lc rgb "#20D500",
            "redgrapes_data" using 1:3 title "RedGrapes" with linespoints lt 9 dt 7 lc rgb "#670496"'

montage $EMPLACE_OUT $SCHEDULE_OUT -geometry +2+1 bench_montage_overhead.png


