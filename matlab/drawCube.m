function drawCube ( origin, size, color )
    x=([0 1 1 0 0 0;1 1 0 0 1 1;1 1 0 0 1 1;0 1 1 0 0 0]-0.5)*size(1)+origin(1);
    y=([0 0 1 1 0 0;0 1 1 0 0 0;0 1 1 0 1 1;0 0 1 1 1 1]-0.5)*size(2)+origin(2);
    z=([0 0 0 0 0 1;0 0 0 0 0 1;1 1 1 1 0 1;1 1 1 1 0 1]-0.5)*size(3)+origin(3);
    for i=1:6
        h=patch(x(:,i),y(:,i),z(:,i),color);
        %h=plot3(x(:,i),y(:,i),z(:,i),'w');
        set(h,'edgecolor','k')
        %surf(x,y,z,'FaceColor','y');
    end
end

