function [eigenvals,eigenvecs] = eigenvalues(obj, pos)
%% EIGENVALUES Eigenvalue analysis of system.
%
%   eigenvals = EIGENVALUES(obj) returns the eigenvalues of obj in
%       the vector eigenvals. Note that the eigenvalues are equal to
%       the square of the circular natural frequencies, not the
%       frequencies themselves.
%
%   [eigenvals,eigenvecs] = EIGENVALUES(obj, pos) returns the eigenvalues
%       in the vector eigenvals and the eigenvectors of the first
%       mode of the column line specified by pos. If pos is not given, the right
%       hand column line is used.
%
if nargin == 1
    pos = 'right';
end

filename_input = obj.scratchFile('strongback_scbf_2d_eigen_input.tcl');
filename_vals  = obj.scratchFile('strongback_scbf_2d_eigen_vals.out');
filename_vecs  = obj.scratchFile('strongback_scbf_2d_eigen_vecs.out');

fid = fopen(filename_input,'w');

obj.constructBuilding(fid)
if obj.includeExplicitPDelta
    obj.applyGravityLoads(fid)
end

fprintf(fid,'############################## Eigenvalue Analysis #############################\n');
fprintf(fid,'set eigs [eigen %i]\n',obj.nStories);
fprintf(fid,'set eigenvalues $eigs\n');
fprintf(fid,'set eigfid [open %s w+]\n',obj.path_for_tcl(filename_vals));
fprintf(fid,'set vecfid [open %s w+]\n',obj.path_for_tcl(filename_vecs));
fprintf(fid,'puts $eigfid $eigs\n');
for i = 1:obj.nStories
    fprintf(fid,'puts $vecfid [nodeEigenvector %i 1 1]\n', obj.tag(pos, i, 1));
end
fprintf(fid,'close $eigfid\n');
fprintf(fid,'close $vecfid\n');
fclose(fid);

[~,~] = obj.runOpenSees(filename_input);

eigenvals = dlmread(filename_vals);
if nargout == 2
    eigenvecs = dlmread(filename_vecs);
end

if obj.deleteFilesAfterAnalysis
    delete(filename_input,filename_vals,filename_vecs);
end

end %function:eigenvalues
