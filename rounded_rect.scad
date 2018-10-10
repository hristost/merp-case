module rounded_rect(size, radius, $fn=$fn) {
    hull(){
        translate([ 1,  1]*radius)circle(r=radius);
        translate([ 1, -1]*radius + [0, size[1]])circle(r=radius);
        translate([-1,  1]*radius + [size[0], 0])circle(r=radius);
        translate([-1, -1]*radius + size)circle(r=radius);
    }
}