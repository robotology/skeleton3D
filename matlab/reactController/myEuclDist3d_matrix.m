function dist = myEuclDist3d_matrix(x1,y1,z1,x2,y2,z2)
    if ((length(x1) == length(y1)) && (length(x1) == length(z1)) && (length(x1) == length(x2)) && (length(x1) == length(y2)) && (length(x1) == length(z2)))
        dist = [];
        for i=1:length(x1)
            dist(i) = sqrt( (x1(i)-x2(i))*(x1(i)-x2(i)) + (y1(i)-y2(i))*(y1(i)-y2(i)) + (z1(i)-z2(i))*(z1(i)-z2(i)) );
        end
    else
        error('input vectors have different lengths');
    end
end

