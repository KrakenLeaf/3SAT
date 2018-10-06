	_____________________________________________________________________________________________

				  Simultaneous Sparsity-Based Super-Resolution And Tracking (3SAT)
	_____________________________________________________________________________________________


** Contents

	1. Overview
	2. Requirements
	3. Installation and basic operation
	4. Copyright
	5. Warranty
	6. History
	7. Download
	8. Trademarks

** Publisher
	
	Oren Solomon				orensol@campus.technion.ac.il
		
	Department of Electrical Engineering
	Technion - Israel Institute of Technology
	Haifa, 32000, Israel

1. Overview

	We present a MATLAB code for simultaneous sparsity-based super-resolution and tracking (3SAT).
	3SAT combines weighted sparse recovery with simultaneous tracking of the individual microbubbles (MBs) to achieve sub-diffraction resolution in (low frame-rate) contrast enhanced ultrasound.
	MBs flow inside blood vessels, hence their movement from one frame to the next is structured. Therefore, MBs are more likely to be found in certain areas of the next frame, given their current locations. 
	Each MB track is used to estimate the position of the MBs and fill-in for the missing spatial information due to low-rate scanning, thus providing a smooth depiction of the super-resolved vessels.
	The code provided here is self-contained and includes all necessary functions. 
	
	Currently, the implementation is single core, but can be extended to multi-core processing.
	
	The code includes an example configuration file and an example simulated movie, along with its by-products.
	
	This code is for academic purposes only.
	
	If you are using this code, please cite: 
    1.	Solomon, Oren, et al. "Exploiting flow dynamics for super-resolution in contrast-enhanced ultrasound.", Arxiv.


2. Requirements

	• MATLAB R2016a or newer (previous versions require modifications).
	• At least 8GB RAM; 64GB or more is recommended.


3. Installation and basic operation
	
	To Install:
	-----------
	1. Unpack the archive and add the 3SAT_V1 folder to the MATLAB path.
	2. AddPathList.m - adds all releveant directories to the path. Can be run once.
	
	To run    :
	-----------
	1. Main.m               - Main file. Just need to run it.
		1. VERBOSE         : 1, 2 - Display massages to screen, 0 - do not display.
		2. DEBUG 		   : 1, 2 - Debug modes (display), 0 - no debug mode.
		3. VIDEO		   : -1 - no video is recorded. 
		4. InternalSaveFlag: 1 - save results to disk, 0 - do not save.
	2. ConfigFile_sim_1.txt - Configuration file. Parameters are changed from this file. Description for different parameters are inside the file.
	
	Main internal functions:
	------------------------
	1. FlowSR.m       - Main computation script, which is called from Main.m.
	2. DrawCovGauss.m - Generates the weighting matrix for each frame. 
	
	'BubbleTracking\':
	1.'MHT\': Third party of the MHT algorithm (Lisbon implementation)
 	2. KalmanCreateMatrixModel.m - Kalman filter tracking models.
	3. KalmanFlow.m 			 - Kalman innovation.
	4. KalmanPropagator.m 		 - Applies Kalman filter propagation equations. 
	5. MHT_init.m 				 - Initialize the MHT algorithm.
	6. MHT_track_frame.m 	     - Performs tracking of detected MBs in a frame.
	7. TrackManager.m 		     - Main file for tracking and managing MB tracks.
	
	
	'OF\':
	1. OFestimator_Preprocess.m - Pre-processing calculations for optical flow estimation.
	2. OFestimator.m 			- Optical flow estimation.
	
	'OptEngine\':
	1. pFISTA_diag_US_3.m    - FISTA based l_1 recovery.
	2. pFISTA_Iterative_US.m - FISTA iterative l_1 reconstruction.
	3. pFISTA_diag_it.m 	 - Additional code for the iterative l_1 procedure.
	4. pFISTA_precalc.m 	 - Pre-processing calculations for the solvers
	5. pfft2.m 				 - FFT calculations.
	
4. Copyright

    Copyright © 2018 Oren Solomon, Department of Electrical Engineering, 
	Technion - Israel Institute of Technology, Haifa, 32000, Israel
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	This code is for academic purposes only.
	
5. Warranty

	Any warranty is strictly refused and you cannot anticipate any financial or
	technical support in case of malfunction or damage; see the copyright notice.

	Feedback and comments are welcome. We will try to track reported problems and
	fix bugs.

	Bugs are encouraged to be reported to orensol@campus.technion.ac.il
	
6. History

  • October 6, 2018
	Version 1.0 released under GNU GPL version 3.


7. Download

	The code is available at http://webee.technion.ac.il/Sites/People/YoninaEldar/software.php
	and on GitHub: https://github.com/KrakenLeaf/3SAT


8. Trademarks

	MATLAB is a registered trademark of The MathWorks. Other product or brand
	names are trademarks or registered trademarks of their respective holders.
	
	All third party software and code packages are disctributed under the GNU license as well. 
	The authors claim no responsibility for this software and code.
