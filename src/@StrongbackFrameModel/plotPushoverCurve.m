function fig = plotPushoverCurve(obj,results,fig)

if nargin == 2
    fig = figure;
    hold on
    grid on
    xlabel(sprintf('Roof drift (%s)',obj.units.length))
    ylabel(sprintf('Base shear (%s)',obj.units.force))
    title('Pushover analysis')
end

ax = fig.Children;
plot(ax,results.roofDrift,results.baseShear,'-')

if nargout == 0
    clear fig
end

end
