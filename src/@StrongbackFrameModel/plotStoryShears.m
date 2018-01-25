function plotStoryShears(obj, results)



fig = figure;
xmax = 0;
plots = obj.nStories:-1:1;
for iStory = 1:obj.nStories
    subplot(obj.nStories, 1, plots(iStory))
    plot(results.storyDrift(:,iStory), results.storyShear(:,iStory))
    xl = xlim;
    xmax = max(xmax, xl(2));
    xlim([0 xmax])
end

end
