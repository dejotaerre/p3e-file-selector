#!/usr/bin/env php
<?php

$file_origen  = "FONTS.OBJ";
$file_destino = "temp.asm";

$bin = file_get_contents($file_origen);

file_put_contents($file_destino,"; SOURCE: $file_origen\n\n");

$n=32;

for ($i=0;$i<(96*8);$i++)
{
	$byte = ord(substr($bin,$i,1));

	$str_bin = sprintf("%08b", $byte);

	$str_mask = str_replace("0","░",$str_bin);
	$str_mask = str_replace("1","█",$str_mask);

	$linea = "\tDB\t%$str_bin\t; $str_mask";

	if ($i % 8 == 0 && $i>0) $linea="\n".$linea;

	if ($i % 8 == 0) $linea=$linea."\tCHR\$ (".$n++.")";

	$linea.="\n";

	file_put_contents($file_destino,$linea,FILE_APPEND);

}

$dst = file_get_contents($file_destino;

echo $dst;

exit(0);