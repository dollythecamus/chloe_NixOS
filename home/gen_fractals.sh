#!/usr/bin/env bash

# Directory to save generated fractals
OUTPUT_DIR="./fractals"
mkdir -p "$OUTPUT_DIR"

# Generate 5 random fractals
for i in $(seq 1 5); do
    # Randomly pick a type: 0=mandelbrot, 1=julia, 2=newton
    type=$((RANDOM % 3))
    
    # Random zoom/scale factor between 100 and 800
    scale=$((100 + RANDOM % 700))
    
    # Random viewport coordinates (for zoom/offset variety)
    llx=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -2 + 4*rand())}')
    lly=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -2 + 4*rand())}')
    trx=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", llx+2)}')
    try=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", lly+2)}')

    output_file="${OUTPUT_DIR}/fractal_${i}.pgm"

    case $type in
        0)
            echo "Generating Mandelbrot fractal $i..."
            fractal --mandelbrot --scale="$scale" \
                --lower-left="${llx},${lly}" --upper-right="${trx},${try}" > "$output_file"
            ;;
        1)
            # Julia fractal with random seed point
            jx=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1.5 + 3*rand())}')
            jy=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1.5 + 3*rand())}')
            echo "Generating Julia fractal $i at ($jx,$jy)..."
            fractal --julia="${jx},${jy}" --scale="$scale" \
                --lower-left="${llx},${lly}" --upper-right="${trx},${try}" > "$output_file"
            ;;
        2)
            # Newton fractal with 3 random roots
            r1x=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            r1y=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            r2x=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            r2y=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            r3x=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            r3y=$(awk -v r=$RANDOM 'BEGIN{srand(r); printf("%.3f", -1 + 2*rand())}')
            echo "Generating Newton fractal $i with roots at (${r1x},${r1y}), (${r2x},${r2y}), (${r3x},${r3y})..."
            fractal --newton="${r1x},${r1y}:${r2x},${r2y}:${r3x},${r3y}" \
                --scale="$scale" --lower-left="${llx},${lly}" --upper-right="${trx},${try}" > "$output_file"
            ;;
    esac
done

echo "All fractals saved in: $OUTPUT_DIR"

