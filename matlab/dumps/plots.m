data=importfile('../data_1400/reactCtrl/data.log');

figure; grid on; hold on;

plot3(data(:,4),data(:,5),data(:,6),'r','Linewidth',2);
plot3(data(:,7),data(:,8),data(:,9),'c','LineWidth',3); 

legend('x_n','x_t');
view(3)

figure; grid on; hold on;
pause(0.1);

for i=1:size(data,1)
    plot3(data(i,10),data(i,11),data(i,12),'*m','LineWidth',3); 
    pause(0.005);
end

legend('x_{delta}');
view(3)

axis equal
