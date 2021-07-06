mcc -m pamsoft_grid.m -d /media/thiago/EXTRALINUX/Upwork/code/pamsoft_grid/standalone -o pamsoft_grid -R -nodisplay
copyfile('util/error_messages.json', 'standalone/error_messages.json');
copyfile('util/properties/default.json', 'standalone/default.json');