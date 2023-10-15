#!/usr/bin/env php
<?php

$bin = file_get_contents("FONTS.OBJ");

file_put_contents("temp.asm","");

$n=32;

for ($i=0;$i<768;$i++)
{
	$byte = ord(substr($bin,$i,1));

	$str_bin = sprintf("%08b", $byte);

	$str_mask = str_replace("0","°",$str_bin);
	$str_mask = str_replace("1","Û",$str_mask);

	$linea = "\tDB\t%$str_bin\t; $str_mask";

	if ($i % 8 == 0 && $i>0) $linea="\n".$linea;

	if ($i % 8 == 0) $linea=$linea." CHR\$ (".$n++.")";

	$linea.="\n";

	file_put_contents("temp.asm",$linea,FILE_APPEND);

}