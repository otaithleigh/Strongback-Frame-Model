function fig = plotPushoverDrifts(obj,results)

fig = figure;
subplot(1,2,1)
barh(results.F/sum(results.F)*100,0.1)
grid on
title('Pushover force distribution')
xlabel('Percent of base shear')
ylabel('Story')
subplot(1,2,2)
hold on

switch results.exitStatus
case 'Analysis Successful'
    plot(results.peakStoryDriftRatio*100  ,1:obj.nStories,'*-')
    plot(results.peak80StoryDriftRatio*100,1:obj.nStories,'*-')
    legend('V_{max}','V_{80}','Location','Southwest')
otherwise
    failedRatio = results.storyDrift(end,:)./obj.storyHeight;
    plot(failedRatio*100  ,1:obj.nStories,'*-')
end

grid on
grid minor
xl = xlim;
xlim([0 xl(2)])
ylim([0.5 obj.nStories+0.5])
ax = gca;
ax.YTick = 1:obj.nStories;
ylabel('Story')
xlabel('Story Drift Ratio (%)')
title('Pushover story drifts')

if nargout == 0
    clear fig
end

end
