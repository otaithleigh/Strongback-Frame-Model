function applyGravityLoads(obj,fid)
%APPLYGRAVITYLOADS  Write gravity load commands to file

    fprintf(fid,'################################# Gravity Loads ################################\n');
    fprintf(fid,'pattern Plain 0 Linear {\n');
    for i = 1:obj.nStories
        fprintf(fid,'    load %4i 0 -%g 0\n', obj.tag('left',i,1), obj.nodalMass(i,'left')*obj.g);
        fprintf(fid,'    load %4i 0 -%g 0\n', obj.tag('right',i,1), obj.nodalMass(i,'right')*obj.g);
        fprintf(fid,'    load %4i 0 -%g 0\n', obj.tag('lean',i,1), obj.nodalMass(i,'lean')*obj.g);
    end
    fprintf(fid,'}\n\n');
    fprintf(fid,'system UmfPack\n');
    fprintf(fid,'constraints %s\n', obj.optionsGravityLoads.constraints.writeArgs());
    fprintf(fid,'numberer RCM\n');
    fprintf(fid,'%s\n', obj.optionsGravityLoads.test.genTclCode(1));
    fprintf(fid,'algorithm %s\n',obj.optionsGravityLoads.algorithm.type{1});
    fprintf(fid,'integrator LoadControl 0.1\n');
    fprintf(fid,'analysis Static\n\n');
    fprintf(fid,'analyze 10\n');
    fprintf(fid,'loadConst -time 0.0\n');
    fprintf(fid,'wipeAnalysis\n\n');
end %function:applyGravityLoads
