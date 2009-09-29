/* Copyright (c) Declan Malone 2009 */
/* Licensed under the terms of GPL v2. See included LICENSE.TXT */

// I/O thread routines

void * single_reader_thread (void *arg);
void * multi_reader_thread (void *arg);
void * single_writer_thread (void *arg);
void * multi_writer_thread (void *arg);

