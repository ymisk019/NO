#include "../include/idt.h"
#include "../include/pic.h"

static idt_entry_t idt_entries[256];
static idt_ptr_t   idt_ptr;
static isr_handler_t interrupt_handlers[256];

void idt_set_gate(uint8_t num, uint32_t base, uint16_t sel, uint8_t flags) {
    idt_entries[num].base_low  = base & 0xFFFF;
    idt_entries[num].base_high = (base >> 16) & 0xFFFF;
    idt_entries[num].sel       = sel;
    idt_entries[num].always0   = 0;
    idt_entries[num].flags     = flags;
}

void register_interrupt_handler(uint8_t n, isr_handler_t handler) {
    interrupt_handlers[n] = handler;
}

extern "C" void default_isr_handler(registers_t* regs) {
    // Unhandled CPU exception: stop here instead of looping or triple-faulting.
    if (regs->int_no < 32 && interrupt_handlers[regs->int_no] == NULL) {
        __asm__ volatile("cli");
        for (;;) {
            __asm__ volatile("hlt");
        }
    }

    if (interrupt_handlers[regs->int_no] != NULL) {
        isr_handler_t handler = interrupt_handlers[regs->int_no];
        handler(regs);
    }

    if (regs->int_no >= 32 && regs->int_no <= 47) {
        pic_send_eoi(regs->int_no - 32);
    }
}

extern "C" uint32_t isr_stub_table[48];

void idt_init(void) {
    idt_ptr.limit = sizeof(idt_entry_t) * 256 - 1;
    idt_ptr.base  = (uint32_t)&idt_entries;

    kmemset(&idt_entries, 0, sizeof(idt_entry_t) * 256);
    kmemset(&interrupt_handlers, 0, sizeof(isr_handler_t) * 256);

    // Install a gate for every vector we have a stub for (CPU exceptions 0..31
    // and hardware IRQs 32..47). Without these, the first timer tick triple-faults.
    for (int i = 0; i < 48; i++) {
        idt_set_gate((uint8_t)i, isr_stub_table[i], 0x08, 0x8E);
    }

    // Remap the PIC so IRQ 0..15 become interrupt 32..47
    pic_remap(0x20, 0x28);

    // Load IDT
    __asm__ volatile("lidt %0" : : "m"(idt_ptr));
}
