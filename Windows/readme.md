#tl;dr

##Answer Files
The answer files are default setup for an en-gb server. The SynchronousCommand should be editied depending on if you want to 
install updates or not. To install updates, make sure you pass the -installUpdates switch 

##Windows Unattend
The unattend file is not specified to run, windows will pick this up by looking at attached drives. This is why the file
needs to be named autounattend.xml. 

##BoxstarterPackage
To build up my core box I utilise boxstarter, for details see here: http://boxstarter.org/
To try and keep my base image as small as possible I remove all windows features apart from web related ones. This is because web stuff will be what I use this for the most. 
Feel free to fork and remove they section if you would like to keep all features install.  

##Building the Box
open up cmd and navigate to the Windows directory of this package. Make sure the Correct ISO has been downloaded and added to the ISO folder(you may need to create the folder too)

Once in cmd, run the following:

```
packer build <filename.json>
eg
packer build server2016.json
```

After the build has completed, run the following command:
```
vagrant box add c:\Git\Packer\windows\windows_2016virtualbox.box --name windows_2016
```


##Running the vagrant box
Navigate to the location you want to keep the files for the box. 

Run the following command:

```
vagrant init windows_2016
vagrant up
```
