#include "stdio.h"
#include "stdlib.h"
#include "string.h"

#define BUFFER_SIZE 200
#define FILE_NAME "dataY.txt"       // Raw 4-bit ADC data
#define NEW_FILE "TB_Data.txt"      // New text file with test bed data
#define VERILOG_VAR_I "temp_data_I" // Variable used for data in verilog code
#define VERILOG_VAR_Q "temp_data_Q" // Variable used for data in verilog code
#define DELAY "#62.5 "              // Needs space after number
#define NEW_DATA "new_data" // Variable used to clock new data in verilog code

int main(int argc, char *argv[]) {

  int DelayInterval = -1;

  for (int i = 0; i < argc; i++) {

    if (strcmp(argv[i], "--help") == 0) {
      printf("\n\".\\test.exe 1 \" = 802.15.4 Mode\t(Sample # = 8)\n");
      printf("\".\\test.exe 0 \" = BLE Mode     \t(Sample # = 16)\n\n");
      return 0;
    }
    // 802.15.4 Mode
    if (strcmp(argv[i], "1") == 0) {
      printf("\n----802.15.4 Mode----\n\n");
      DelayInterval = 9; // 8 + 1
    }
    // BLE Mode
    if (strcmp(argv[i], "0") == 0) {
      printf("\n----BLE Mode----\n\n");
      DelayInterval = 17; // 16 + 1
    }
  }
  if (DelayInterval == -1) {
    printf("\n----Missing\\Incorrect Argument!----\n");
    printf("\ttry \"--help\"\n\n");
    return 0;
  }

  char buffer1[BUFFER_SIZE / 2];
  char buffer2[BUFFER_SIZE / 2];
  char buffer3[BUFFER_SIZE / 2];
  char buffer4[BUFFER_SIZE / 2];
  char newline[BUFFER_SIZE];
  int lineCount = 1;
  int counter = 1;
  FILE *fptr;
  FILE *ftemp;

  memset(buffer1, 0, strlen(buffer1));
  memset(buffer2, 0, strlen(buffer2));
  memset(buffer3, 0, strlen(buffer3));
  memset(buffer4, 0, strlen(buffer4));
  memset(newline, 0, strlen(newline));

  // Open files
  fptr = fopen(FILE_NAME, "r");
  ftemp = fopen(NEW_FILE, "w");
  // Check if files were opened correctly
  if (fptr == NULL || ftemp == NULL) {
    // Failed to open file
    printf("Failed to open file\n");
    exit(EXIT_SUCCESS);
  }

  int Idata;
  int Qdata;

  while ((fgets(buffer2, BUFFER_SIZE, fptr)) != NULL) {

    sscanf(buffer2, "%d\t%d", &Idata, &Qdata);

    buffer2[strcspn(buffer2, "\n")] = 0; // remove "\n" from file buffer
    if (lineCount == 1) {
      strcpy(buffer1, VERILOG_VAR_I " = 4'd");
      strcpy(buffer4, VERILOG_VAR_Q " = 4'd");
    } else {
      strcpy(buffer1, DELAY VERILOG_VAR_I " = 4'd");
      strcpy(buffer4, VERILOG_VAR_Q " = 4'd");
    }
    strcat(buffer1, itoa(Idata, buffer2, 10));
    strcat(buffer4, itoa(Qdata, buffer3, 10));
    strcpy(buffer3, ";\n");
    strcat(buffer1, buffer3);
    strcat(buffer4, buffer3);

    // Verilog data clock
    if (counter == DelayInterval) {
      strcpy(buffer3, NEW_DATA " = 1;\n");
      strcat(buffer4, buffer3);
    }
    if (counter == DelayInterval + 1) {
      strcpy(buffer3, NEW_DATA " = 0;\n");
      strcat(buffer4, buffer3);
      counter = 2;
    }
    strcat(buffer1, buffer4);
    strcpy(newline, buffer1);
    fputs(newline, ftemp);
    lineCount++;
    counter++;
  }
  fclose(fptr);
  fclose(ftemp);
  return 0;
}
