function len = reducedLengths(obj)
%REDUCEDLENGTHS  Outputs the reduced brace lengths due to gusset plates and frame members.

len = zeros(2,obj.nStories);
for i = 1:obj.nStories
    for j = 1:2
        if j == 1
            panel_length = sqrt((obj.bracePos*obj.bayWidth)^2 + obj.storyHeight(i)^2);
        else
            panel_length = sqrt(((1-obj.bracePos)*obj.bayWidth)^2 + obj.storyHeight(i)^2);
        end
        bot = obj.GussetPlates{i,j,1}.L2 + obj.GussetPlates{i,j,1}.L4;
        top = obj.GussetPlates{i,j,2}.L2 + obj.GussetPlates{i,j,2}.L4;
        len(j,i) = panel_length - bot - top;
    end
end
