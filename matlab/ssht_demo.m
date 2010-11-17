function ssht_demo
%%
% SSHT_DEMO - Compute forward and inverse spherical harmonic transforms
% 
% Harmonic transforms are computed by calling the fortran programs
% ssht_forward and ssht_inverse through the command line (these 
% executables should be contained in the same directory as ssht_demo.m).
%
% Author: Jason McEwen (jason.mcewen@epfl.ch)
% Date: November 2010

% Define size parameters.
spin = 0;
reality = 1;
verbosity = 1;
L = 5;
nphi = 2*L - 1;
ntheta_dh = 2*L;
ntheta_mw = L;

% Define sample points.
t_dh = 0:ntheta_dh-1;
theta_dh =  (2d0*t_dh+1d0)*pi / (4d0*L)
t_mw = 0:ntheta_mw-1;
theta_mw = (2d0*t_mw+1d0)*pi / (2d0*L - 1d0)
p = 0:nphi-1;
phi_dh = 2d0*p*pi / (2d0*L - 1d0)
phi_mw = 2d0*p*pi / (2d0*L - 1d0)

% Random flms (of complex signal).
flm = zeros(L^2,1);
flm = rand(size(flm)) + sqrt(-1)*rand(size(flm));
flm = 2.*(flm - (1+sqrt(-1))./2);
ind_min = spin^2 + abs(spin);
flm(1:ind_min) = 0;

% Impose reality on flms.
if (reality == 1)
   for el = 0:L-1
      m = 0;
      ind = el^2 + el + m;
      flm(ind+1) = real(flm(ind+1));
      for m = 1:el
         ind_pm = el^2 + el + m;
         ind_nm = el^2 + el - m;
         flm(ind_nm+1) = (-1)^m * conj(flm(ind_pm+1));
      end
   end
end

% Measure error of inverse-forward transform for DH.
f_dh = ssht_inverse(flm, 'DH', L, spin, reality, verbosity);
flm_dh_syn = ssht_forward(f_dh, 'DH', L, spin, reality, verbosity);
maxerr_dh = max(abs(flm - flm_dh_syn))

% Measure error of inverse-forward transform for MW.
f_mw = ssht_inverse(flm, 'MW', L, spin, reality, verbosity);
f_mw_grid = reshape(f_mw, nphi, ntheta_mw)
f_mw_grid(:,end) = f_mw_grid(1,end).*exp(sqrt(-1)*spin*phi_mw);%.* ...
%   exp(sqrt(-1)*(-1d0)*pi / (2d0*L - 1d0)*spin);
f_mw = f_mw_grid(:);
flm_mw_syn = ssht_forward(f_mw, 'MW', L, spin, reality, verbosity);
maxerr_mw = max(abs(flm - flm_mw_syn))


% Define sample points and function values on grids.
f_dh_grid = reshape(f_dh, nphi, ntheta_dh);
[theta_dh_grid, phi_dh_grid] = meshgrid(theta_dh, phi_dh);
f_mw_grid = reshape(f_mw, nphi, ntheta_mw);
[theta_mw_grid, phi_mw_grid] = meshgrid(theta_mw, phi_mw);



function flm = ssht_forward(f, method, L, spin, reality, verbosity)
%% Compute forward spherical harmonic transform for method={'DH','MW'}.

f_save = [real(f), imag(f)];
save('f.txt', 'f_save', '-ascii', '-double');

cmd = sprintf('%s%s%s%s%s%s', ...
   '../bin/ssht_forward -inp f.txt -out flm.txt -method ', ...
   method(1:2), ' -L ', num2str(L), ' -spin ', num2str(spin), ...
   ' -reality ', num2str(reality), ' -verbosity ', num2str(verbosity));
system(cmd);

flm = load('flm.txt');
flm = flm(:,1) + sqrt(-1)*flm(:,2);

system('rm -f flm.txt f.txt');


function f = ssht_inverse(flm, method, L, spin, reality, verbosity)
%% Compute inverse spherical harmonic transform for method={'DH','MW'}.

flm_save = [real(flm), imag(flm)];
save('flm.txt', 'flm_save', '-ascii', '-double');

cmd = sprintf('%s%s%s%s%s%s', ...
   '../bin/ssht_inverse -inp flm.txt -out f.txt -method ', ...
   method(1:2), ' -L ', num2str(L), ' -spin ', num2str(spin), ...
   ' -reality ', num2str(reality), ' -verbosity ', num2str(verbosity));
system(cmd);

f = load('f.txt');
if(reality ~= 1)
   f = f(:,1) + sqrt(-1)*f(:,2);
end

system('rm -f flm.txt f.txt');