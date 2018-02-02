function animateResponseHistory(obj,results,f,dt)

if nargin < 2
    f = [];
end
if nargin < 3
    dt = max(diff(results.time));
end

if isempty(f)
    f = 10;
end

cumHeights = cumsum(obj.storyHeight);

figure

grid on
grid minor

xMax = 1.5*obj.bayWidth;
xMin = -0.5*obj.bayWidth;
yMax = sum(obj.storyHeight) + 0.5*obj.storyHeight(1);

axis([xMin, xMax, 0 yMax]);
ax = gca;
ax.YTick = cumHeights;

ylabel(sprintf('Y-position (%s)',obj.units.length))
xlabel(sprintf('X-position (%s)',obj.units.length))

xPos = f*results.disp_x + results.coords_x;
yPos = f*results.disp_y + results.coords_y;

h = animatedline(xPos(1,:),yPos(1,:),'Marker','.','LineStyle','none');
% t = text(2/3*xMax,1/5*yMax,'Time: 0.0s');

for i = 1:size(xPos,1)
    % displayText = sprintf('Time: %4.1fs',i*dt);
    % delete(t)
    clearpoints(h)
    addpoints(h, xPos(i,:), yPos(i,:))
    % t = text(ax, 2/3*xMax, 1/5*yMax, displayText);
    drawnow
end

end
