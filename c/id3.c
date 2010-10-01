/*********************************************************************
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*                   Version 2, December 2004                         *
*                                                                    *
*  Copyleft meh.                                                     *
*                                                                    *
*           DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE              *
*  TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION   *
*                                                                    *
*  0. You just DO WHAT THE FUCK YOU WANT TO.                         *
**********************************************************************
* Just a useless ID3 tag reader.                                     *
*                                                                    *
* gcc -o id3 id3.c -lid3tag                                          *
*********************************************************************/

#include <stdio.h>
#include <string.h>
#include <id3tag.h>

int __unique_frame (struct id3_tag *tag, struct id3_frame *frame)
{
    int i;

    for (i = 0; i < tag->nframes; i++) {
        if (tag->frames[i] == frame) {
            break;
        }
    }

    for (; i < tag->nframes; i++) {
        if (strcmp(tag->frames[i]->id, frame->id) == 0) {
            return 0;
        }
    }

    return 1;
}

char*
getTag (struct id3_tag* tag, const char* what)
{
    struct id3_frame*  frame;
    union  id3_field*  field;
    const  id3_ucs4_t* ucs4;
    char*              ret = NULL;

    frame = id3_tag_findframe(tag, what, 0);
    if (!frame || !(field = &frame->fields[1])) {
        return NULL;
    }

    ucs4 = id3_field_getstrings(field, 0);

    if (!ucs4) {
        return NULL;
    }

    if ((id3_tag_options(tag, 0, 0) & ID3_TAG_OPTION_ID3V1) && __unique_frame(tag, frame)) {
        ret = (char*) id3_ucs4_latin1duplicate(ucs4);
    }
    else {
        ret = (char*) id3_ucs4_utf8duplicate(ucs4);
    }

    return ret;
}

int
main (int argc, char** argv)
{
    struct id3_file* file;
    struct id3_tag*  tag;

    if (argc < 2) {
        fprintf(stderr, "Usage: %s <file>\n", argv[0]);
        return -1;
    }

    file = id3_file_open(argv[1], ID3_FILE_MODE_READONLY);
    if (file == NULL) {
        fprintf(stderr, "Something went wrong wile opening the file.\n");
        return -2;
    }

    tag = id3_file_tag(file);
    if (tag == NULL) {
        fprintf(stderr, "Something went wrong while getting the primary tag.\n");
        return -3;
    }

    printf("Track:  %s\n", getTag(tag, ID3_FRAME_TRACK));
    printf("Title:  %s\n", getTag(tag, ID3_FRAME_TITLE));
    printf("Album:  %s\n", getTag(tag, ID3_FRAME_ALBUM));
    printf("Genre:  %s\n", getTag(tag, ID3_FRAME_GENRE));
    printf("Artist: %s\n", getTag(tag, ID3_FRAME_ARTIST));
    printf("Year:   %s\n", getTag(tag, ID3_FRAME_YEAR));

    return 0;
}

