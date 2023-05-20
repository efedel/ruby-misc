/*
 * bfd.c
 */

#include <ruby.h>

#include <bfd.h>

/* ----------------------------------------------------------------------  */
/* Bfd class object */
static VALUE clsBfd = Qnill;

static VALUE clsBfd_alloc( VALUE class_def ) {
	/* bfd open based on argument type? */
}

/* ----------------------------------------------------------------------  */
/* BFD module object */
static VALUE modBFD = Qnil;

void Init_bfd() {
	/* initialize BFD library */
	bfd_init();

	/* register ruby module */
	modBFD = rb_define_module("BFD");

	/* build ruby Bfd class */
	clsBfd = rb_define_class_under( modBFD, "Bfd", rb_cObject );
	//rb_define_alloc_fn( clsBfd, clsBfd_alloc );

}
