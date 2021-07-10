clear all
load 5ag05Short_x.txt
load 5ag05Short_z.txt
figure
hold on

for i = 2:length(X5ag05Short_x)
    plot([X5ag05Short_x(i-1),X5ag05Short_x(i)],[X5ag05Short_z(i-1),X5ag05Short_z(i)])
    hold on
    set(gca,'YDir','reverse');        %将x轴方向设置为反向(从上到下递增)。
    drawnow 
end

